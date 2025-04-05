// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./PrintAccessControl.sol";
import "./NFTCreator.sol";
import "./CollectionCreator.sol";
import "./PrintLibrary.sol";
import "./PrintErrors.sol";

contract PrintDesignData {
    PrintAccessControl public printAccessControl;
    CollectionCreator public collectionCreator;
    NFTCreator public nftCreator;
    string public symbol;
    string public name;
    uint256 private _collectionSupply;
    uint256 private _dropSupply;
    uint256 private _tokenSupply;

    mapping(uint256 => PrintLibrary.Collection) private _collections;
    mapping(uint256 => PrintLibrary.Drop) private _drops;
    mapping(uint256 => PrintLibrary.Token) private _tokens;
    mapping(uint256 => mapping(address => bool)) private _acceptedTokens;

    event TokensMinted(uint256 indexed tokenId, uint256 collectionId);
    event CollectionCreated(
        uint256 indexed collectionId,
        uint256 postId,
        string uri,
        uint256 amount,
        address owner
    );
    event DropCollectionsUpdated(
        uint256 dropId,
        uint256[] collectionIds,
        uint256[] oldCollectionIds,
        string uri
    );
    event DropCreated(uint256 dropId, string uri, address creator);
    event DropDeleted(uint256 dropId);
    event CollectionDeleted(uint256 collectionId);
    event CollectionMintedTokensSet(
        uint256 indexed collectionId,
        uint256 mintedTokensAmount
    );
    event CollectionTokenIdsSet(
        uint256 indexed collectionId,
        uint256[] tokenIds
    );

    modifier onlyCollectionCreator() {
        if (msg.sender != address(collectionCreator)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    constructor(address printAccessControlAddress) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        _collectionSupply = 0;
        _tokenSupply = 0;
        _dropSupply = 0;
        symbol = "PDD";
        name = "PrintDesignData";
    }

    function setCollection(
        PrintLibrary.Collection memory collectionData
    ) external onlyCollectionCreator returns (uint256) {
        _collectionSupply++;

        if (_drops[collectionData.dropId].dropId == 0) {
            revert PrintErrors.InvalidDrop();
        }

        _collections[_collectionSupply] = collectionData;

        for (uint256 i = 0; i < collectionData.acceptedTokens.length; i++) {
            _acceptedTokens[_collectionSupply][
                collectionData.acceptedTokens[i]
            ] = true;
        }

        emit CollectionCreated(
            _collectionSupply,
            collectionData.postId,
            collectionData.uri,
            collectionData.amount,
            collectionData.creator
        );

        return _collectionSupply;
    }

    function setCollectionMintedTokens(
        uint256 collectionId,
        uint256 mintedTokens
    ) external onlyCollectionCreator {
        _collections[collectionId].mintedTokens += mintedTokens;

        emit CollectionMintedTokensSet(
            collectionId,
            _collections[collectionId].mintedTokens
        );
    }

    function setCollectionTokenIds(
        uint256[] memory newTokenIds,
        uint256 collectionId
    ) external onlyCollectionCreator {
        _collections[collectionId].tokenIds = _concatenate(
            _collections[collectionId].tokenIds,
            newTokenIds
        );
        emit CollectionTokenIdsSet(
            collectionId,
            _collections[collectionId].tokenIds
        );
    }

    function modifyCollectionsInDrop(
        uint256[] memory collectionIds,
        string memory uri,
        uint256 dropId
    ) external onlyCollectionCreator {
        uint256[] memory _oldCollectionIds = _drops[dropId].collectionIds;
        for (uint256 i = 0; i < _oldCollectionIds.length; i++) {
            _collections[_oldCollectionIds[i]].dropId = 0;
        }

        for (uint256 i = 0; i < collectionIds.length; i++) {
            _collections[collectionIds[i]].dropId = dropId;
        }

        _drops[dropId].collectionIds = collectionIds;
        _drops[dropId].uri = uri;

        emit DropCollectionsUpdated(
            dropId,
            collectionIds,
            _oldCollectionIds,
            uri
        );
    }

    function deleteCollection(
        uint256 collectionId
    ) external onlyCollectionCreator {
        delete _collections[collectionId];

        emit CollectionDeleted(collectionId);
    }

    function createDrop(
        string memory uri,
        address creator
    ) external onlyCollectionCreator {
        _dropSupply++;

        _drops[_dropSupply] = PrintLibrary.Drop({
            dropId: _dropSupply,
            collectionIds: new uint256[](0),
            uri: uri,
            creator: creator
        });

        emit DropCreated(_dropSupply, uri, creator);
    }

    function deleteDrop(uint256 dropId) external onlyCollectionCreator {
        for (uint256 i = 0; i < _drops[dropId].collectionIds.length; i++) {
            _collections[_drops[dropId].collectionIds[i]].dropId = 0;
        }

        delete _drops[dropId];

        emit DropDeleted(dropId);
    }

    function setNFT(PrintLibrary.Token memory tokenData) external {
        if (msg.sender != address(nftCreator)) {
            revert PrintErrors.InvalidAddress();
        }
        _tokenSupply++;

        _tokens[_tokenSupply] = tokenData;

        emit TokensMinted(_tokenSupply, _tokens[_tokenSupply].collectionId);
    }

    function getCollectionCreator(
        uint256 collectionId
    ) public view returns (address) {
        return _collections[collectionId].creator;
    }

    function getCollectionCommunityIds(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].communityIds;
    }

    function getCollectionAcceptedTokens(
        uint256 collectionId
    ) public view returns (address[] memory) {
        return _collections[collectionId].acceptedTokens;
    }

    function getIsCollectionTokenAccepted(
        uint256 collectionId,
        address tokenAddress
    ) public view returns (bool) {
        return _acceptedTokens[collectionId][tokenAddress];
    }

    function getCollectionOrigin(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].origin;
    }

    function getCollectionDropId(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].dropId;
    }

    function getCollectionURI(
        uint256 collectionId
    ) public view returns (string memory) {
        return _collections[collectionId].uri;
    }

    function getCollectionPrices(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].prices;
    }

    function getCollectionPrintType(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].printType;
    }

    function getCollectionFulfiller(
        uint256 collectionId
    ) public view returns (address) {
        return _collections[collectionId].fulfiller;
    }

    function getCollectionAmount(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].amount;
    }

    function getCollectionUnlimited(
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].unlimited;
    }

    function getCollectionEncrypted(
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].encrypted;
    }

    function getCollectionTokenIds(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].tokenIds;
    }

    function getCollectionTokensMinted(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].mintedTokens;
    }

    function getCollectionPostId(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].postId;
    }

    function getCollectionSupply() public view returns (uint256) {
        return _collectionSupply;
    }

    function getTokenSupply() public view returns (uint256) {
        return _tokenSupply;
    }

    function getDropSupply() public view returns (uint256) {
        return _dropSupply;
    }

    function getTokenCollection(uint256 tokenId) public view returns (uint256) {
        return _tokens[tokenId].collectionId;
    }

    function getTokenIndex(uint256 tokenId) public view returns (uint256) {
        return _tokens[tokenId].index;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokens[tokenId].uri;
    }

    function getDropURI(uint256 dropId) public view returns (string memory) {
        return _drops[dropId].uri;
    }

    function getDropCreator(uint256 dropId) public view returns (address) {
        return _drops[dropId].creator;
    }

    function getDropCollectionIds(
        uint256 dropId
    ) public view returns (uint256[] memory) {
        return _drops[dropId].collectionIds;
    }

    function _concatenate(
        uint256[] memory originalArray,
        uint256[] memory newArray
    ) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](
            originalArray.length + newArray.length
        );
        uint256 i;
        for (i = 0; i < originalArray.length; i++) {
            result[i] = originalArray[i];
        }
        for (uint256 j = 0; j < newArray.length; j++) {
            result[i++] = newArray[j];
        }
        return result;
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setCollectionCreatorAddress(
        address newCollectionCreatorAddress
    ) public onlyAdmin {
        collectionCreator = CollectionCreator(newCollectionCreatorAddress);
    }

    function setNFTCreatorAddress(
        address newNFTCreatorAddress
    ) public onlyAdmin {
        nftCreator = NFTCreator(newNFTCreatorAddress);
    }
}
