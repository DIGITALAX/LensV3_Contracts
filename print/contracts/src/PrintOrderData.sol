// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./MarketCreator.sol";
import "./PrintDesignData.sol";
import "./PrintErrors.sol";

contract PrintOrderData {
    PrintAccessControl public printAccessControl;
    MarketCreator public marketCreator;
    PrintDesignData public printDesignData;
    string public symbol;
    string public name;
    uint256 private _orderSupply;
    uint256 private _nftOnlyOrderSupply;
    uint256 private _subOrderSupply;
    mapping(uint256 => PrintLibrary.NFTOnlyOrder) private _nftOnlyOrders;
    mapping(uint256 => PrintLibrary.Order) private _orders;
    mapping(uint256 => PrintLibrary.SubOrder) private _subOrders;
    mapping(address => uint256[]) private _addressToOrderIds;
    mapping(address => uint256[]) private _addressToNFTOnlyOrderIds;
    mapping(address => uint256[]) private _communityHelperAddressToTokenIds;

    event UpdateSubOrderStatus(
        uint256 indexed subOrderId,
        PrintLibrary.OrderStatus newSubOrderStatus
    );
    event UpdateOrderDetails(uint256 indexed orderId, string newOrderDetails);
    event SubOrderIsFulfilled(uint256 indexed subOrderId);
    event OrderCreated(
        uint256 orderId,
        uint256 totalPrice,
        address currency,
        uint256 postId,
        address buyer
    );
    event NFTOnlyOrderCreated(
        uint256 orderId,
        uint256 totalPrice,
        address currency,
        uint256 postId,
        address buyer
    );
    event UpdateOrderMessage(uint256 indexed orderId, string newMessageDetails);
    event UpdateNFTOnlyOrderMessage(
        uint256 indexed orderId,
        string newMessageDetails
    );

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }
    modifier onlyMarketContract() {
        if (msg.sender != address(marketCreator)) {
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
    modifier fulfillerIncluded(uint256[] memory subOrderIds) {
        bool isFulfiller = false;
        for (uint256 i = 0; i < subOrderIds.length; i++) {
            if (_subOrders[subOrderIds[i]].fulfiller == msg.sender) {
                isFulfiller = true;
                break;
            }
        }
        if (!isFulfiller) {
            revert PrintErrors.InvalidFulfiller();
        }
        _;
    }

    constructor(
        address printAccessControlAddress,
        address printDesignDataAddress
    ) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printDesignData = PrintDesignData(printDesignDataAddress);
        _orderSupply = 0;
        _subOrderSupply = 0;
        _nftOnlyOrderSupply = 0;
        symbol = "POD";
        name = "PrintOrderData";
    }

    function createOrder(
        uint256[] memory subOrderIds,
        string memory details,
        address chosenCurrency,
        address buyer,
        uint256 postId,
        uint256 totalPrice
    ) external onlyMarketContract {
        _orderSupply++;
        PrintLibrary.Order memory newOrder = PrintLibrary.Order({
            orderId: _orderSupply,
            postId: postId,
            subOrderIds: subOrderIds,
            details: details,
            buyer: buyer,
            chosenCurrency: chosenCurrency,
            timestamp: block.timestamp,
            messages: new string[](0),
            totalPrice: totalPrice
        });

        _orders[_orderSupply] = newOrder;
        _addressToOrderIds[buyer].push(_orderSupply);

        emit OrderCreated(
            _orderSupply,
            totalPrice,
            chosenCurrency,
            postId,
            buyer
        );
    }

    function createNFTOnlyOrder(
        uint256[] memory tokenIds,
        address chosenCurrency,
        address buyer,
        uint256 postId,
        uint256 totalPrice,
        uint256 collectionId,
        uint256 amount
    ) external onlyMarketContract {
        _nftOnlyOrderSupply++;
        PrintLibrary.NFTOnlyOrder memory newOrder = PrintLibrary.NFTOnlyOrder({
            orderId: _nftOnlyOrderSupply,
            postId: postId,
            amount: amount,
            buyer: buyer,
            chosenCurrency: chosenCurrency,
            timestamp: block.timestamp,
            messages: new string[](0),
            totalPrice: totalPrice,
            collectionId: collectionId,
            tokenIds: tokenIds
        });

        _nftOnlyOrders[_nftOnlyOrderSupply] = newOrder;

        _addressToNFTOnlyOrderIds[buyer].push(_nftOnlyOrderSupply);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _communityHelperAddressToTokenIds[buyer].push(tokenIds[i]);
        }

        emit NFTOnlyOrderCreated(
            _nftOnlyOrderSupply,
            totalPrice,
            chosenCurrency,
            postId,
            buyer
        );
    }

    function createSubOrder(
        uint256[] memory tokenIds,
        address fullfiller,
        address buyer,
        uint256 amount,
        uint256 orderId,
        uint256 price,
        uint256 collectionId
    ) external onlyMarketContract {
        _subOrderSupply++;
        PrintLibrary.SubOrder memory newSubOrder = PrintLibrary.SubOrder({
            subOrderId: _subOrderSupply,
            collectionId: collectionId,
            tokenIds: tokenIds,
            amount: amount,
            orderId: orderId,
            price: price,
            status: PrintLibrary.OrderStatus.Designing,
            isFulfilled: false,
            fulfiller: fullfiller
        });

        _subOrders[_subOrderSupply] = newSubOrder;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _communityHelperAddressToTokenIds[buyer].push(tokenIds[i]);
        }
    }

    function setSubOrderisFulfilled(
        uint256 subOrderId
    ) external onlyFulfiller(_subOrders[subOrderId].fulfiller) {
        _subOrders[subOrderId].isFulfilled = true;
        emit SubOrderIsFulfilled(subOrderId);
    }

    function setSubOrderStatus(
        uint256 subOrderId,
        PrintLibrary.OrderStatus status
    ) external onlyFulfiller(_subOrders[subOrderId].fulfiller) {
        _subOrders[subOrderId].status = status;
        emit UpdateSubOrderStatus(subOrderId, status);
    }

    function setOrderDetails(
        string memory newDetails,
        uint256 orderId
    ) external {
        if (_orders[orderId].buyer != msg.sender) {
            revert PrintErrors.InvalidAddress();
        }
        _orders[orderId].details = newDetails;
        emit UpdateOrderDetails(orderId, newDetails);
    }

    function setOrderMessage(
        string memory newMessage,
        uint256 orderId
    ) external fulfillerIncluded(_orders[orderId].subOrderIds) {
        _orders[orderId].messages.push(newMessage);
        emit UpdateOrderMessage(orderId, newMessage);
    }

    function setNFTOnlyOrderMessage(
        string memory newMessage,
        uint256 orderId
    ) external {
        if (
            msg.sender !=
            printDesignData.getCollectionCreator(
                _nftOnlyOrders[orderId].collectionId
            )
        ) {
            revert PrintErrors.InvalidAddress();
        }
        _nftOnlyOrders[orderId].messages.push(newMessage);
        emit UpdateNFTOnlyOrderMessage(orderId, newMessage);
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setMarketCreatorAddress(
        address newMarketCreatorAddress
    ) public onlyAdmin {
        marketCreator = MarketCreator(newMarketCreatorAddress);
    }

    function setPrintDesignDataAddress(
        address newPrintDesignDataAddress
    ) public onlyAdmin {
        printDesignData = PrintDesignData(newPrintDesignDataAddress);
    }

    function getSubOrderTokenIds(
        uint256 subOrderId
    ) public view returns (uint256[] memory) {
        return _subOrders[subOrderId].tokenIds;
    }

    function getOrderDetails(
        uint256 orderId
    ) public view returns (string memory) {
        return _orders[orderId].details;
    }

    function getOrderMessages(
        uint256 orderId
    ) public view returns (string[] memory) {
        return _orders[orderId].messages;
    }

    function getOrderBuyer(uint256 orderId) public view returns (address) {
        return _orders[orderId].buyer;
    }

    function getOrderChosenCurrency(
        uint256 orderId
    ) public view returns (address) {
        return _orders[orderId].chosenCurrency;
    }

    function getOrderTimestamp(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].timestamp;
    }

    function getOrderTotalPrice(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].totalPrice;
    }

    function getOrderPostId(uint256 orderId) public view returns (uint256) {
        return _orders[orderId].postId;
    }

    function getSubOrderStatus(
        uint256 subOrderId
    ) public view returns (PrintLibrary.OrderStatus) {
        return _subOrders[subOrderId].status;
    }

    function getSubOrderIsFulfilled(
        uint256 subOrderId
    ) public view returns (bool) {
        return _subOrders[subOrderId].isFulfilled;
    }

    function getSubOrderFulfiller(
        uint256 subOrderId
    ) public view returns (address) {
        return _subOrders[subOrderId].fulfiller;
    }

    function getSubOrderOrderId(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].orderId;
    }

    function getSubOrderCollectionId(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].collectionId;
    }

    function getSubOrderAmount(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].amount;
    }

    function getSubOrderPrice(
        uint256 subOrderId
    ) public view returns (uint256) {
        return _subOrders[subOrderId].price;
    }

    function getOrderSubOrders(
        uint256 orderId
    ) public view returns (uint256[] memory) {
        return _orders[orderId].subOrderIds;
    }

    function getAddressToTokenIds(
        address _address
    ) public view returns (uint256[] memory) {
        return _communityHelperAddressToTokenIds[_address];
    }

    function getOrderSupply() public view returns (uint256) {
        return _orderSupply;
    }

    function getSubOrderSupply() public view returns (uint256) {
        return _subOrderSupply;
    }

    function getNFTOnlyOrderSupply() public view returns (uint256) {
        return _nftOnlyOrderSupply;
    }

    function getNFTOnlyOrderPostId(
        uint256 orderId
    ) public view returns (uint256) {
        return _nftOnlyOrders[orderId].postId;
    }

    function getNFTOnlyOrderChosenCurrency(
        uint256 orderId
    ) public view returns (address) {
        return _nftOnlyOrders[orderId].chosenCurrency;
    }

    function getNFTOnlyOrderTimestamp(
        uint256 orderId
    ) public view returns (uint256) {
        return _nftOnlyOrders[orderId].timestamp;
    }

    function getNFTOnlyOrderMessages(
        uint256 orderId
    ) public view returns (string[] memory) {
        return _nftOnlyOrders[orderId].messages;
    }

    function getNFTOnlyOrderTotalPrice(
        uint256 orderId
    ) public view returns (uint256) {
        return _nftOnlyOrders[orderId].totalPrice;
    }

    function getNFTOnlyOrderCollectionId(
        uint256 orderId
    ) public view returns (uint256) {
        return _nftOnlyOrders[orderId].collectionId;
    }

    function getNFTOnlyOrderBuyer(
        uint256 orderId
    ) public view returns (address) {
        return _nftOnlyOrders[orderId].buyer;
    }

    function getNFTOnlyOrderAmount(
        uint256 orderId
    ) public view returns (uint256) {
        return _nftOnlyOrders[orderId].amount;
    }

    function getNFTOnlyOrderTokenIds(
        uint256 orderId
    ) public view returns (uint256[] memory) {
        return _nftOnlyOrders[orderId].tokenIds;
    }

    function getAddressToNFTOnlyOrderIds(
        address _address
    ) public view returns (uint256[] memory) {
        return _addressToNFTOnlyOrderIds[_address];
    }

    function getAddressToOrderIds(
        address _address
    ) public view returns (uint256[] memory) {
        return _addressToOrderIds[_address];
    }
}
