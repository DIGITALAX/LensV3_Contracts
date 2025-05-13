// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./MarketCreator.sol";
import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./PrintSplitsData.sol";
import "./PrintErrors.sol";

contract CollectionCreator {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    PrintAccessControl public printAccessControl;
    PrintSplitsData public printSplitsData;
    string public name;
    address public marketCreator;
    uint256 private _collectionSupply;
    uint256 private _dropSupply;

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.AddressNotAdmin();
        }
        _;
    }

    modifier onlyDesigner() {
        if (!printAccessControl.isDesigner(msg.sender)) {
            revert PrintErrors.AddressNotDesigner();
        }
        _;
    }

    modifier onlyAction() {
        if (!printAccessControl.isAction(msg.sender)) {
            revert PrintErrors.InvalidAddress();
        }
        _;
    }

    modifier onlyCollectionCreator(uint256 collectionId) {
        if (_collections[collectionId].designer != msg.sender) {
            revert PrintErrors.AddressNotDesigner();
        }
        _;
    }

    modifier onlyDropCreator(uint256 dropId) {
        if (_drops[dropId].designer != msg.sender) {
            revert PrintErrors.AddressNotDesigner();
        }
        _;
    }

    mapping(uint256 => PrintLibrary.Collection) private _collections;
    mapping(uint256 => PrintLibrary.Drop) private _drops;
    mapping(uint256 => mapping(uint8 => uint256)) private _tokensToCollectionId;

    event CollectionFrozen(uint256 collectionId);
    event CollectionUnfrozen(uint256 collectionId);
    event CollectionCreated(
        string uri,
        address designer,
        uint256 collectionId,
        uint256 postId,
        uint256 amount
    );
    event CollectionDeleted(uint256 collectionId);
    event CollectionTokenIdsSet(uint256[] tokenIds, uint256 collectionId);
    event DropCreated(string uri, address designer, uint256 dropId);
    event DropDeleted(uint256 dropId);
    event DropModified(uint256 dropId);

    constructor(
        address printAccessControlAddress,
        address printSplitsDataAddress
    ) {
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printSplitsData = PrintSplitsData(printSplitsDataAddress);
        name = "CollectionCreator";
    }

    function createCollection(
        PrintLibrary.CollectionInitParams memory params,
        address designer,
        uint256 postId,
        uint8 origin
    ) external onlyAction returns (uint256) {
        uint256 _amount = params.amount;
        if (params.unlimited) {
            _amount = type(uint256).max;
        }


        if (
            _drops[params.dropId].dropId == 0 ||
            _drops[params.dropId].designer != designer
        ) {
            revert PrintErrors.InvalidDrop();
        }

        _collectionSupply++;

        _collections[_collectionSupply].collectionId = _collectionSupply;
        _collections[_collectionSupply].amount = _amount;
        _collections[_collectionSupply].postId = postId;
        _collections[_collectionSupply].dropId = params.dropId;
        _collections[_collectionSupply].fulfiller = params.fulfiller;
        _collections[_collectionSupply].designer = designer;
        _collections[_collectionSupply].uri = params.uri;
        _collections[_collectionSupply].printType = params.printType;
        _collections[_collectionSupply].origin = origin;
        _collections[_collectionSupply].unlimited = params.unlimited;
        _collections[_collectionSupply].price = params.price;

        for (uint256 i = 0; i < params.acceptedTokens.length; i++) {
            _collections[_collectionSupply].acceptedTokens.add(
                params.acceptedTokens[i]
            );
        }

        _drops[params.dropId].collectionIds.add(_collectionSupply);

        emit CollectionCreated(
            params.uri,
            designer,
            _collectionSupply,
            postId,
            params.amount
        );

        return _collectionSupply;
    }

    function createDrop(string memory uri) public onlyDesigner {
        _dropSupply++;

        _drops[_dropSupply].dropId = _dropSupply;
        _drops[_dropSupply].designer = msg.sender;
        _drops[_dropSupply].uri = uri;

        emit DropCreated(uri, msg.sender, _dropSupply);
    }

    function setCollectionMintedTokens(
        uint256[] memory newTokenIds,
        uint256 collectionId
    ) external {
        if (marketCreator != msg.sender) {
            revert PrintErrors.InvalidUpdate();
        }


        for (uint8 i = 0; i < newTokenIds.length; i++) {
            _collections[collectionId].mintedTokenIds.add(newTokenIds[i]);
            _tokensToCollectionId[newTokenIds[i]][
                _collections[collectionId].origin
            ] = collectionId;
        }

        emit CollectionTokenIdsSet(
            _collections[collectionId].mintedTokenIds.values(),
            collectionId
        );
    }

    function freezeCollection(
        uint256 collectionId
    ) public onlyDesigner onlyCollectionCreator(collectionId) {
        _collections[collectionId].freeze = true;

        emit CollectionFrozen(collectionId);
    }

    function unfreezeCollection(
        uint256 collectionId
    ) public onlyDesigner onlyCollectionCreator(collectionId) {
        _collections[collectionId].freeze = false;

        emit CollectionUnfrozen(collectionId);
    }

    function removeCollection(
        uint256 collectionId
    ) public onlyDesigner onlyCollectionCreator(collectionId) {
        if (_collections[collectionId].mintedTokenIds.length() > 0) {
            revert PrintErrors.InvalidRemoval();
        }

        _drops[_collections[collectionId].dropId].collectionIds.remove(
            collectionId
        );

        delete _collections[collectionId];

        emit CollectionDeleted(collectionId);
    }

    function modifyDrop(
        uint256[] memory collectionIds,
        string memory uri,
        uint256 dropId
    ) public onlyDesigner onlyDropCreator(dropId) {
        _drops[dropId].uri = uri;

        uint256[] memory _colls = _drops[dropId].collectionIds.values();

        for (uint8 i = 0; i < collectionIds.length; i++) {
            if (_collections[collectionIds[i]].designer != msg.sender) {
                revert PrintErrors.AddressNotDesigner();
            }
        }

        for (uint8 i = 0; i < _colls.length; i++) {
            _collections[_colls[i]].dropId = 0;
            _drops[dropId].collectionIds.remove(_colls[i]);
        }

        for (uint8 i = 0; i < collectionIds.length; i++) {
            _collections[collectionIds[i]].dropId = dropId;
            _drops[dropId].collectionIds.add(collectionIds[i]);
        }

        emit DropModified(dropId);
    }

    function deleteDrop(
        uint256 dropId
    ) public onlyDesigner onlyDropCreator(dropId) {
        if (bytes(_drops[dropId].uri).length == 0) {
            revert PrintErrors.InvalidUpdate();
        }

        for (uint256 i = 0; i < _drops[dropId].collectionIds.length(); i++) {
            _collections[_drops[dropId].collectionIds.at(i)].dropId = 0;
        }

        delete _drops[dropId];

        emit DropDeleted(dropId);
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function setPrintSplitsDataAddress(
        address newPrintSplitsDataAddress
    ) public onlyAdmin {
        printSplitsData = PrintSplitsData(newPrintSplitsDataAddress);
    }

    function setMarketCreatorAddress(
        address newMarketCreatorAddress
    ) public onlyAdmin {
        marketCreator = newMarketCreatorAddress;
    }

    function getCollectionDesigner(
        uint256 collectionId
    ) public view returns (address) {
        return _collections[collectionId].designer;
    }

    function getCollectionAcceptedTokens(
        uint256 collectionId
    ) public view returns (address[] memory) {
        return _collections[collectionId].acceptedTokens.values();
    }

    function getIsAcceptedToken(
        address currency,
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].acceptedTokens.contains(currency);
    }

    function getCollectionOrigin(
        uint256 collectionId
    ) public view returns (uint8) {
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

    function getCollectionPrice(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].price;
    }

    function getCollectionPrintType(
        uint256 collectionId
    ) public view returns (uint8) {
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

    function getCollectionMintedTokenIds(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].mintedTokenIds.values();
    }

    function getCollectionFrozen(
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].freeze;
    }

    function getCollectionPostId(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].postId;
    }

    function getCollectionSupply() public view returns (uint256) {
        return _collectionSupply;
    }

    function getDropSupply() public view returns (uint256) {
        return _dropSupply;
    }

    function getTokenURI(
        uint256 tokenId,
        uint8 origin
    ) public view returns (string memory) {
        return _collections[_tokensToCollectionId[tokenId][origin]].uri;
    }

    function getDropURI(uint256 dropId) public view returns (string memory) {
        return _drops[dropId].uri;
    }

    function getDropDesigner(uint256 dropId) public view returns (address) {
        return _drops[dropId].designer;
    }

    function getDropCollectionIds(
        uint256 dropId
    ) public view returns (uint256[] memory) {
        return _drops[dropId].collectionIds.values();
    }
}
