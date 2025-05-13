// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PrintLibrary {
    enum OrderStatus {
        Fulfilled,
        Shipped,
        Shipping,
        Designing
    }

    struct CollectionInitParams {
        address[] acceptedTokens;
        string uri;
        address fulfiller;
        uint256 price;
        uint256 dropId;
        uint256 amount;
        uint8 printType;
        bool unlimited;
    }

    struct Collection {
        EnumerableSet.AddressSet acceptedTokens;
        EnumerableSet.UintSet mintedTokenIds;
        string uri;
        address fulfiller;
        address designer;
        uint256 price;
        uint256 collectionId;
        uint256 postId;
        uint256 dropId;
        uint256 amount;
        uint8 origin;
        uint8 printType;
        bool unlimited;
        bool freeze;
    }

    struct BuyParms {
        string[] details;
        address[] currencies;
        uint256[] collectionIds;
        uint8[] amounts;
        uint8[] origins;
        address buyer;
    }

    struct Drop {
        EnumerableSet.UintSet collectionIds;
        string uri;
        address designer;
        uint256 dropId;
    }

    struct Order {
        string[] messages;
        uint256[] tokenIds;
        string details;
        address buyer;
        address currency;
        address fulfiller;
        uint256 orderId;
        uint256 timestamp;
        uint256 price;
        uint256 collectionId;
        uint8 amount;
        OrderStatus status;
        bool isFulfilled;
    }

    struct Currency {
        uint256 weiAmount;
        uint256 rate;
    }

    struct Splits {
        uint256 fulfillerSplit;
        uint256 fulfillerBase;
    }
}
