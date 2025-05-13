// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract FGOLibrary {
    enum OrderStatus {
        Fulfilled,
        Shipped,
        Shipping,
        Designing
    }

    struct ChildMetadata {
        string uri;
        uint256 price;
    }

    struct ParentMetadata {
        uint256[] childIds;
        string uri;
        string poster;
        uint256 price;
        uint8 printType;
    }

    struct Order {
        string[] messages;
        string details;
        address buyer;
        address currency;
        uint256 parentId;
        uint256 orderId;
        uint256 timestamp;
        uint256 price;
        uint256 parentTokenId;
        uint256 tokenId;
        OrderStatus status;
        bool isFulfilled;
    }

    struct BuyParms {
        string details;
        string uri;
        address currency;
        uint256 parentId;
    }
}
