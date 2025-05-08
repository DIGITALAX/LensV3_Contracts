// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./PrintAccessControl.sol";
import "./NFTCreator.sol";
import "./PrintSplitsData.sol";
import "./PrintErrors.sol";

contract MarketCreator {
    PrintAccessControl public printAccessControl;
    NFTCreator public nftCreator;
    CollectionCreator public collectionCreator;
    PrintSplitsData public printSplitsData;
    string public symbol;
    string public name;
    uint256 private _orderSupply;

    mapping(uint256 => PrintLibrary.Order) private _orders;
    mapping(address => uint256[]) private _buyerToOrderIds;

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    modifier onlyOpenAction() {
        if (!printAccessControl.isAction(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    modifier onlyFulfiller(address fulfiller) {
        if (fulfiller != msg.sender) {
            revert PrintErrors.InvalidFulfiller();
        }
        _;
    }

    event UpdateOrderStatus(
        uint256 indexed orderId,
        PrintLibrary.OrderStatus newSubOrderStatus
    );
    event UpdateOrderDetails(uint256 indexed orderId);
    event OrderIsFulfilled(uint256 indexed orderId);
    event OrderCreated(
        address buyer,
        uint256 collectionId,
        uint256 orderId,
        uint256 totalPrice
    );
    event UpdateOrderMessage(string newMessageDetails, uint256 indexed orderId);

    constructor(
        address printAccessControlAddress,
        address nftCreatorAddress,
        address collectionCreatorAddress
    ) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        nftCreator = NFTCreator(nftCreatorAddress);
        collectionCreator = CollectionCreator(collectionCreatorAddress);
        symbol = "MCR";
        name = "MarketCreator";
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setNFTCreatorAddress(
        address newNFTCreatorAddress
    ) public onlyAdmin {
        nftCreator = NFTCreator(newNFTCreatorAddress);
    }

    function setCollectionCreatorAddress(
        address newCollectionCreatorAddress
    ) public onlyAdmin {
        collectionCreator = CollectionCreator(newCollectionCreatorAddress);
    }

    function buyTokens(
        PrintLibrary.BuyParms memory params
    ) external onlyOpenAction {
        for (uint8 i = 0; i < params.collectionIds.length; i++) {
            uint256[] memory _tokenIds = nftCreator.mintTokens(
                params.buyer,
                params.amounts[i],
                params.origins[i]
            );

            collectionCreator.setCollectionMintedTokens(
                _tokenIds,
                params.collectionIds[i]
            );

            _createOrder(
                _tokenIds,
                params.details[i],
                params.buyer,
                params.currencies[i],
                params.collectionIds[i],
                params.amounts[i]
            );
        }
    }

    function _createOrder(
        uint256[] memory tokenIds,
        string memory details,
        address buyer,
        address currency,
        uint256 collectionId,
        uint8 amount
    ) internal {
        _orderSupply++;
        uint256 _price = collectionCreator.getCollectionPrice(collectionId) *
            amount;

        address _fulfiller = collectionCreator.getCollectionFulfiller(
            collectionId
        );

        bool _fulfilled = false;
        PrintLibrary.OrderStatus _status = PrintLibrary.OrderStatus.Designing;
        if (collectionCreator.getCollectionPrintType(collectionId) == 6) {
            _fulfilled = true;
            _status = PrintLibrary.OrderStatus.Fulfilled;
        }

        PrintLibrary.Order memory newOrder = PrintLibrary.Order({
            orderId: _orderSupply,
            tokenIds: tokenIds,
            buyer: buyer,
            timestamp: block.timestamp,
            messages: new string[](0),
            price: _price,
            details: details,
            fulfiller: _fulfiller,
            collectionId: collectionId,
            amount: amount,
            currency: currency,
            status: _status,
            isFulfilled: _fulfilled
        });

        _orders[_orderSupply] = newOrder;
        _buyerToOrderIds[buyer].push(_orderSupply);

        emit OrderCreated(buyer, collectionId, _orderSupply, _price);
    }

    function setOrderStatus(
        uint256 orderId,
        PrintLibrary.OrderStatus status
    ) external onlyFulfiller(_orders[orderId].fulfiller) {
        _orders[orderId].status = status;
        emit UpdateOrderStatus(orderId, status);
    }

    function setOrderDetails(
        string memory newDetails,
        uint256 orderId
    ) external {
        if (_orders[orderId].buyer != msg.sender) {
            revert PrintErrors.InvalidAddress();
        }

        _orders[orderId].details = newDetails;

        emit UpdateOrderDetails(orderId);
    }

    function setOrderMessage(
        string memory newMessage,
        uint256 orderId
    ) external onlyFulfiller(_orders[orderId].fulfiller) {
        _orders[orderId].messages.push(newMessage);
        emit UpdateOrderMessage(newMessage, orderId);
    }

    function getOrderTokenIds(
        uint256 orderId
    ) public view returns (uint256[] memory) {
        return _orders[orderId].tokenIds;
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
    ) public view returns (PrintLibrary.OrderStatus) {
        return _orders[orderId].status;
    }

    function getOrderFulfiller(uint256 orderId) public view returns (address) {
        return _orders[orderId].fulfiller;
    }

    function getOrderCurrency(uint256 orderId) public view returns (address) {
        return _orders[orderId].currency;
    }

    function getOrderDetails(
        uint256 orderId
    ) public view returns (string memory) {
        return _orders[orderId].details;
    }

    function getOrderCollectionId(
        uint256 orderId
    ) public view returns (uint256) {
        return _orders[orderId].collectionId;
    }

    function getOrderAmount(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].amount;
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
