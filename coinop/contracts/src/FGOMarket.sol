// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./FGOAccessControl.sol";
import "./CustomCompositeNFT.sol";
import "./ParentFGO.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/PrintSplitsData.sol";

contract FGOMarket {
    FGOAccessControl public accessControl;
    CustomCompositeNFT public customComposite;
    PrintSplitsData public printSplitsData;
    ParentFGO public parentFGO;
    ChildFGO public childFGO;
    string public symbol;
    string public name;
    uint256 private _orderSupply;

    mapping(uint256 => FGOLibrary.Order) private _orders;
    mapping(address => uint256[]) private _buyerToOrderIds;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    event UpdateOrderStatus(
        uint256 indexed orderId,
        FGOLibrary.OrderStatus newSubOrderStatus
    );
    event UpdateOrderDetails(uint256 indexed orderId);
    event OrderIsFulfilled(uint256 indexed orderId);
    event OrderCreated(
        address buyer,
        uint256 parentId,
        uint256 orderId,
        uint256 totalPrice
    );
    event UpdateOrderMessage(string newMessageDetails, uint256 indexed orderId);

    constructor(
        address _accessControl,
        address _customComposite,
        address _parentFGO,
        address _printSplitsData,
        address _childFGO
    ) {
        accessControl = FGOAccessControl(_accessControl);
        customComposite = CustomCompositeNFT(_customComposite);
        parentFGO = ParentFGO(_parentFGO);
        printSplitsData = PrintSplitsData(_printSplitsData);
        childFGO = ChildFGO(_childFGO);
        symbol = "MFGO";
        name = "FGOMarket";
    }

    function buyComposites(FGOLibrary.BuyParms[] memory params) external {
        for (uint8 i = 0; i < params.length; i++) {
            if (!printSplitsData.getIsCurrency(params[i].currency)) {
                revert PrintErrors.CurrencyNotWhitelisted();
            }
        }

        for (uint8 i = 0; i < params.length; i++) {
            uint256 _total = _transferTokens(
                params[i].currency,
                msg.sender,
                params[i].parentId
            );

            uint256 _tokenId = customComposite.mint(params[i].uri, msg.sender);

            uint256 _parentTokenId = parentFGO.mintParentWithChildren(
                msg.sender,
                params[i].parentId
            );

            _createOrder(
                params[i],
                msg.sender,
                _total,
                _parentTokenId,
                _tokenId
            );
        }
    }

    function _createOrder(
        FGOLibrary.BuyParms memory params,
        address buyer,
        uint256 price,
        uint256 parentTokenId,
        uint256 tokenId
    ) internal {
        _orderSupply++;

        FGOLibrary.Order memory newOrder = FGOLibrary.Order({
            orderId: _orderSupply,
            parentTokenId: parentTokenId,
            buyer: buyer,
            timestamp: block.timestamp,
            messages: new string[](0),
            price: price,
            details: params.details,
            tokenId: tokenId,
            parentId: params.parentId,
            currency: params.currency,
            status: FGOLibrary.OrderStatus.Designing,
            isFulfilled: false
        });

        _orders[_orderSupply] = newOrder;
        _buyerToOrderIds[buyer].push(_orderSupply);

        emit OrderCreated(buyer, params.parentId, _orderSupply, price);
    }

    function setOrderStatus(
        uint256 orderId,
        FGOLibrary.OrderStatus status
    ) external onlyAdmin {
        _orders[orderId].status = status;
        emit UpdateOrderStatus(orderId, status);
    }

    function setOrderDetails(
        string memory newDetails,
        uint256 orderId
    ) external {
        if (_orders[orderId].buyer != msg.sender) {
            revert FGOErrors.AddressInvalid();
        }

        _orders[orderId].details = newDetails;

        emit UpdateOrderDetails(orderId);
    }

    function setAccessControl(address _accessControl) public onlyAdmin {
        accessControl = FGOAccessControl(_accessControl);
    }

    function setCustomCompositeNFT(address _customComposite) public onlyAdmin {
        customComposite = CustomCompositeNFT(_customComposite);
    }

    function setParentFGO(address _parentFGO) public onlyAdmin {
        parentFGO = ParentFGO(_parentFGO);
    }

    function setChildFGO(address _childFGO) public onlyAdmin {
        childFGO = ChildFGO(_childFGO);
    }

    function setPrintSplitsData(address _printSplitsData) public onlyAdmin {
        printSplitsData = PrintSplitsData(_printSplitsData);
    }

    function _transferTokens(
        address currency,
        address buyer,
        uint256 parentId
    ) internal returns (uint256) {
        uint256 _parentPrice = parentFGO.getParentPrice(parentId);
        uint256[] memory _childIds = parentFGO.getParentChildIds(parentId);
        uint256 _childPrice = 0;

        for (uint8 i = 0; i < _childIds.length; i++) {
            _childPrice += childFGO.getChildPrice(_childIds[i]);
        }

        uint256 _totalPrice = _parentPrice + _childPrice;

        uint256 _calculatedPrice = _calculateAmount(currency, _totalPrice);
        IERC20(currency).transferFrom(
            buyer,
            accessControl.getFulfiller(),
            _calculatedPrice
        );

        return _calculatedPrice;
    }

    function _calculateAmount(
        address currency,
        uint256 amountInWei
    ) internal view returns (uint256) {
        if (amountInWei == 0) {
            revert PrintErrors.InvalidAmounts();
        }

        uint256 _exchangeRate = printSplitsData.getCurrencyRate(currency);
        uint256 _weiDivisor = printSplitsData.getCurrencyWei(currency);
        uint256 _tokenAmount = (amountInWei * _weiDivisor) / _exchangeRate;
        return _tokenAmount;
    }

    function setOrderMessage(
        string memory newMessage,
        uint256 orderId
    ) external onlyAdmin {
        _orders[orderId].messages.push(newMessage);
        emit UpdateOrderMessage(newMessage, orderId);
    }

    function getOrderTokenId(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].tokenId;
    }

    function getOrderParentId(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].parentId;
    }

    function getOrderParentTokenId(
        uint256 orderId
    ) public view returns (uint256) {
        return _orders[orderId].parentTokenId;
    }

    function getOrderMessages(
        uint256 orderId
    ) public view returns (string[] memory) {
        return _orders[orderId].messages;
    }

    function getOrderBuyer(uint256 orderId) public view returns (address) {
        return _orders[orderId].buyer;
    }

    function getOrderTimestamp(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].timestamp;
    }

    function getOrderTotalPrice(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].price;
    }

    function getOrderStatus(
        uint256 orderId
    ) public view returns (FGOLibrary.OrderStatus) {
        return _orders[orderId].status;
    }

    function getOrderCurrency(uint256 orderId) public view returns (address) {
        return _orders[orderId].currency;
    }

    function getOrderDetails(
        uint256 orderId
    ) public view returns (string memory) {
        return _orders[orderId].details;
    }

    function getOrderIsFulfilled(uint256 orderId) public view returns (bool) {
        return _orders[orderId].isFulfilled;
    }

    function getOrderSupply() public view returns (uint256) {
        return _orderSupply;
    }

    function getBuyerToOrderIds(
        address buyer
    ) public view returns (uint256[] memory) {
        return _buyerToOrderIds[buyer];
    }
}
