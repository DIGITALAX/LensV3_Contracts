// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographAccessControl.sol";
import "./AutographData.sol";
import "./AutographNFT.sol";
import "./AutographCollections.sol";
import "./AutographLibrary.sol";
import "./AutographErrors.sol";
import "./AutographCatalog.sol";
import "./CatalogNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AutographMarket {
    AutographAccessControl public autographAccessControl;
    AutographCatalog public autographCatalog;
    AutographNFT public autographNFT;
    CatalogNFT public catalogNFT;
    AutographData public autographData;
    AutographCollections public autographCollections;
    string public symbol;
    string public name;
    uint256 private _orderCounter;
    uint256 private _subOrderCounter;

    modifier onlyOpenAction() {
        if (!autographAccessControl.isAction(msg.sender)) {
            revert AutographErrors.InvalidAddress();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.InvalidAddress();
        }
        _;
    }

    event OrderCreated(uint256[] subOrderIds, uint256 total, uint256 orderId);

    mapping(address => uint256[]) private _buyerToOrders;
    mapping(uint256 => AutographLibrary.Order) private _orders;
    mapping(uint256 => AutographLibrary.SubOrder) private _subOrders;

    constructor(
        address _autographAccessControl,
        address _autographCatalog,
        address _autographCollections,
        address _autographNFT,
        address _catalogNFT,
        address _autographData
    ) {
        symbol = "AM";
        name = "AutographMarket";
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        autographCollections = AutographCollections(_autographCollections);
        autographCatalog = AutographCatalog(_autographCatalog);
        autographNFT = AutographNFT(_autographNFT);
        catalogNFT = CatalogNFT(_catalogNFT);
        autographData = AutographData(_autographData);
    }

    function buyTokens(
        address[] memory currencies,
        uint256[] memory collectionIds,
        uint8[] memory quantities,
        string memory encryptedFulfillment
    ) external {
        uint256 _total = 0;
        uint256[] memory _subOrderIds = new uint256[](currencies.length);
        for (uint256 i = 0; i < currencies.length; i++) {
            (uint256 _subOrderId, uint256 _itemTotal) = _processType(
                msg.sender,
                currencies[i],
                collectionIds[i],
                quantities[i]
            );
            _subOrderIds[i] = _subOrderId;
            _total += _itemTotal;
        }

        _createOrder(_subOrderIds, encryptedFulfillment, msg.sender, _total);
    }

    function buyTokenAction(
        string memory encryptedFulfillment,
        address buyer,
        address currency,
        uint256 collectionId,
        uint8 quantity
    ) external onlyOpenAction {
        (uint256 _subOrderId, uint256 _total) = _processType(
            buyer,
            currency,
            collectionId,
            quantity
        );

        uint256[] memory _subOrderIds = new uint256[](1);
        _subOrderIds[0] = _subOrderId;

        _createOrder(_subOrderIds, encryptedFulfillment, buyer, _total);
    }

    function _processType(
        address buyer,
        address currency,
        uint256 collectionId,
        uint8 amount
    ) internal returns (uint256, uint256) {
        AutographLibrary.AutographType _autographType = AutographLibrary
            .AutographType
            .Catalog;
        if (collectionId != 0) {
            _autographType = autographCollections.getCollectionType(
                collectionId
            );
        }

        _checkAcceptedTokens(currency, collectionId, amount, _autographType);

        _subOrderCounter++;

        uint256[] memory _nftIds;
        address _designer = address(0);
        address _fulfiller = address(0);
        uint256 _designerAmount = 0;
        uint256 _fulfillerAmount = 0;
        uint256 _totalPrice = 0;

        if (_autographType == AutographLibrary.AutographType.Catalog) {
            _designerAmount = autographCatalog.getAutographPrice() * amount;
            _totalPrice = _designerAmount;
            _designer = autographCatalog.getAutographDesigner();

            _processPayment(buyer, _designer, currency, _designerAmount);

            _nftIds = catalogNFT.mintBatch(buyer, amount);
        } else {
            uint256 _base = 0;
            _fulfiller = autographAccessControl.fulfiller();
            _designer = autographCollections.getCollectionDesigner(
                collectionId
            );
            _designerAmount =
                autographCollections.getCollectionPrice(collectionId) *
                amount;
            _totalPrice = _designerAmount;
            if (_autographType != AutographLibrary.AutographType.NFT) {
                if (_autographType == AutographLibrary.AutographType.Hoodie) {
                    _base = autographData.getHoodieBase();
                } else {
                    _base = autographData.getShirtBase();
                }

                _fulfillerAmount = (_base *
                    amount +
                    (((_designerAmount - _base * amount) *
                        autographData.getVig()) / 100));

                _designerAmount = _designerAmount - _fulfillerAmount;
            }

            if (_fulfiller != address(0) && _fulfillerAmount > 0) {
                _processPayment(buyer, _fulfiller, currency, _fulfillerAmount);
            }

            _processPayment(buyer, _designer, currency, _designerAmount);

            _nftIds = autographNFT.mintCollection(buyer, amount);
            autographCollections.setTokenIdsToCollection(_nftIds, collectionId);
        }

        _subOrders[_subOrderCounter] = AutographLibrary.SubOrder({
            autographType: _autographType,
            fulfillerAmount: _fulfillerAmount,
            designerAmount: _designerAmount,
            fulfiller: _fulfiller,
            designer: _designer,
            total: _totalPrice,
            currency: currency,
            collectionId: collectionId,
            amount: amount,
            mintedTokenIds: _nftIds
        });

        return (_subOrderCounter, _totalPrice);
    }

    function _processPayment(
        address buyer,
        address to,
        address currency,
        uint256 amount
    ) internal {
        uint256 _exchangeRate = autographData.getCurrencyRate(currency);

        if (_exchangeRate == 0) {
            revert AutographErrors.InvalidAmounts();
        }

        uint256 _weiDivisor = autographData.getCurrencyWei(currency);
        uint256 _tokenAmount = (amount * _weiDivisor) / _exchangeRate;

        IERC20(currency).transferFrom(buyer, to, _tokenAmount);
    }

    function _createOrder(
        uint256[] memory subOrders,
        string memory fulfillment,
        address buyer,
        uint256 total
    ) internal {
        _orderCounter++;

        _buyerToOrders[buyer].push(_orderCounter);

        _orders[_orderCounter] = AutographLibrary.Order({
            subOrderIds: subOrders,
            buyer: buyer,
            total: total,
            fulfillment: fulfillment
        });

        emit OrderCreated(subOrders, total, _orderCounter);
    }

    function _checkAcceptedTokens(
        address currency,
        uint256 collectionId,
        uint256 amount,
        AutographLibrary.AutographType autographType
    ) internal view {
        if (autographType == AutographLibrary.AutographType.Catalog) {
            if (!autographCatalog.isAcceptedToken(currency)) {
                revert AutographErrors.CurrencyNotWhitelisted();
            }

            if (
                autographCatalog.getAutographMinted() + amount >
                autographCatalog.getAutographAmount()
            ) {
                revert AutographErrors.ExceedAmount();
            }
        } else {
            if (
                !autographCollections.getCollectionIsAcceptedToken(
                    currency,
                    collectionId
                )
            ) {
                revert AutographErrors.CurrencyNotWhitelisted();
            }

            if (
                autographCollections
                    .getCollectionMintedTokenIds(collectionId)
                    .length +
                    amount >
                autographCollections.getCollectionAmount(collectionId)
            ) {
                revert AutographErrors.ExceedAmount();
            }

            if (
                autographCollections.getCollectionType(collectionId) !=
                autographType
            ) {
                revert AutographErrors.InvalidType();
            }
        }
    }

    function setAutographAccessControl(
        address _autographAccessControl
    ) public onlyAdmin {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function setAutographCatalog(address _autographCatalog) public onlyAdmin {
        autographCatalog = AutographCatalog(_autographCatalog);
    }

    function setAutographCollections(
        address _autographCollections
    ) public onlyAdmin {
        autographCollections = AutographCollections(_autographCollections);
    }

    function setAutographNFT(address _autographNFT) public onlyAdmin {
        autographNFT = AutographNFT(_autographNFT);
    }

    function setCatalogNFT(address _catalogNFT) public onlyAdmin {
        catalogNFT = CatalogNFT(_catalogNFT);
    }

    function setAutographData(address _autographData) public onlyAdmin {
        autographData = AutographData(_autographData);
    }

    function getBuyerOrderIds(
        address buyer
    ) public view returns (uint256[] memory) {
        return _buyerToOrders[buyer];
    }

    function getOrderSubOrderIds(
        uint256 orderId
    ) public view returns (uint256[] memory) {
        return _orders[orderId].subOrderIds;
    }

    function getOrderFulfillment(
        uint256 orderId
    ) public view returns (string memory) {
        return _orders[orderId].fulfillment;
    }

    function getOrderTotal(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].total;
    }

    function getOrderBuyer(uint256 orderId) public view returns (address) {
        return _orders[orderId].buyer;
    }

    function getSubOrderType(
        uint256 subOrderId
    ) public view returns (AutographLibrary.AutographType) {
        return _subOrders[subOrderId].autographType;
    }

    function getSubOrderAmount(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].amount;
    }

    function getSubOrderCollectionId(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].collectionId;
    }

    function getSubOrderTotal(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].total;
    }

    function getSubOrderDesignerAmount(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].designerAmount;
    }

    function getSubOrderFulfillerAmount(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].fulfillerAmount;
    }

    function getSubOrderCurrency(
        uint256 subOrderId
    ) public view returns (address) {
        return _subOrders[subOrderId].currency;
    }

    function getSubOrderDesigner(
        uint256 subOrderId
    ) public view returns (address) {
        return _subOrders[subOrderId].designer;
    }

    function getSubOrderFulfiller(
        uint256 subOrderId
    ) public view returns (address) {
        return _subOrders[subOrderId].fulfiller;
    }

    function getSubOrderTokensMinted(
        uint256 subOrderId
    ) public view returns (uint256[] memory) {
        return _subOrders[subOrderId].mintedTokenIds;
    }

    function getOrderCounter() public view returns (uint256) {
        return _orderCounter;
    }

    function getSubOrderCounter() public view returns (uint256) {
        return _subOrderCounter;
    }
}
