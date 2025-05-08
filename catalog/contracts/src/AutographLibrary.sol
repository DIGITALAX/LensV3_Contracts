// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AutographLibrary {
    enum AutographType {
        NFT,
        Hoodie,
        Shirt,
        Catalog
    }

    struct ActionParams {
        address[] acceptedTokens;
        string[] pages;
        string uri;
        uint256 collectionId;
        uint256 price;
        uint256 amount;
        uint8 pageCount;
        AutographType autographType;
    }

    struct AutographInit {
        string[] pages;
        address[] acceptedTokens;
        string uri;
        address designer;
        uint256 price;
        uint256 amount;
        uint256 postId;
        uint8 pageCount;
    }

    struct Autograph {
        string[] pages;
        EnumerableSet.AddressSet acceptedTokens;
        string uri;
        address designer;
        uint256 price;
        uint256 minted;
        uint256 amount;
        uint256 postId;
        uint8 pageCount;
    }

    struct CollectionInit {
        address[] npcs;
        address[] acceptedTokens;
        string uri;
        uint256 price;
        uint256 amount;
        AutographType collectionType;
    }

    struct Collection {
        EnumerableSet.AddressSet npcs;
        EnumerableSet.AddressSet acceptedTokens;
        EnumerableSet.UintSet mintedTokenIds;
        uint256[] postIds;
        string uri;
        address designer;
        uint256 price;
        uint256 galleryId;
        uint256 amount;
        AutographType collectionType;
    }

    struct Gallery {
        EnumerableSet.UintSet collectionIds;
        string uri;
        address designer;
    }

    struct Currency {
        uint256 weiAmount;
        uint256 rate;
    }

    struct Order {
        uint256[] subOrderIds;
        string fulfillment;
        address buyer;
        uint256 total;
    }

    struct SubOrder {
        uint256[] mintedTokenIds;
        address fulfiller;
        address designer;
        address currency;
        uint256 fulfillerAmount;
        uint256 designerAmount;
        uint256 total;
        uint256 collectionId;
        uint16 amount;
        AutographType autographType;
    }
}
