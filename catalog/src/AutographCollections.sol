// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "./AutographAccessControl.sol";
import "./AutographData.sol";
import "./AutographErrors.sol";
import "./AutographMarket.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AutographCollections {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    AutographAccessControl public autographAccessControl;
    AutographData public autographData;
    address public autographMarket;
    uint256 private _collectionCounter;
    uint256 private _galleryCounter;

    mapping(uint256 => AutographLibrary.Collection) private _collections;
    mapping(address => EnumerableSet.UintSet) private _npcToCollections;
    mapping(uint256 => EnumerableSet.AddressSet) private _collectionToNPCs;
    mapping(address => EnumerableSet.UintSet) private _designerGalleries;
    mapping(uint256 => AutographLibrary.Gallery) private _galleries;
    mapping(uint256 => uint256) private _tokenIdToCollection;

    event GalleryCreated(address designer, uint256 galleryId);
    event GalleryUpdated(address designer, uint256 galleryId);
    event GalleryDeleted(address designer, uint256 galleryId);
    event CollectionDeleted(uint256 collectionId, uint256 galleryId);

    modifier onlyDesigner() {
        if (!autographAccessControl.isDesigner(msg.sender)) {
            revert AutographErrors.AddressNotVerified();
        }
        _;
    }

    modifier onlyMarket() {
        if (msg.sender != address(autographMarket)) {
            revert AutographErrors.AddressNotVerified();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.AddressNotVerified();
        }
        _;
    }

    constructor(address _autographAccessControlAddress) {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
    }

    function createGallery(
        AutographLibrary.CollectionInit[] memory colls,
        string memory galleryURI
    ) public onlyDesigner {
        _galleryCounter++;
        _designerGalleries[msg.sender].add(_galleryCounter);
        _galleries[_galleryCounter].uri = galleryURI;

        for (uint8 i = 0; i < colls.length; i++) {
            _collectionCounter++;

            _galleries[_galleryCounter].collectionIds.add(_collectionCounter);

            _collections[_collectionCounter].galleryId = _galleryCounter;
            _collections[_collectionCounter].uri = colls[i].uri;
            _collections[_collectionCounter].amount = colls[i].amount;
            _collections[_collectionCounter].price = colls[i].price;
            _collections[_collectionCounter].collectionType = colls[i]
                .collectionType;
            _collections[_collectionCounter].designer = msg.sender;

            for (uint8 j = 0; j < colls[i].acceptedTokens.length; j++) {
                _collections[_collectionCounter].acceptedTokens.add(
                    colls[i].acceptedTokens[j]
                );
            }

            for (uint8 j = 0; j < colls[i].npcs.length; j++) {
                _collections[_collectionCounter].npcs.add(colls[i].npcs[j]);
            }

            for (uint8 k = 0; k < colls[i].npcs.length; k++) {
                _npcToCollections[colls[i].npcs[k]].add(_collectionCounter);
                _collectionToNPCs[_collectionCounter].add(colls[i].npcs[k]);
            }
        }

        emit GalleryCreated(msg.sender, _galleryCounter);
    }

    function deleteGallery(uint16 galleryId) public onlyDesigner {
        if (_galleries[galleryId].designer != msg.sender) {
            revert AutographErrors.AddressNotVerified();
        }

        for (
            uint256 i = 0;
            i < _galleries[galleryId].collectionIds.length();
            i++
        ) {
            uint256 _id = _galleries[galleryId].collectionIds.at(i);

            for (uint256 j = 0; j < _collectionToNPCs[_id].length(); j++) {
                _npcToCollections[_collectionToNPCs[_id].at(j)].remove(_id);
            }

            delete _collectionToNPCs[_id];
            delete _collections[_id];
        }

        _designerGalleries[msg.sender].remove(galleryId);
        delete _galleries[galleryId];

        emit GalleryDeleted(msg.sender, galleryId);
    }

    function deleteCollection(uint256 collectionId) public onlyDesigner {
        uint256 _galleryId = _collections[collectionId].galleryId;
        if (!_galleries[_galleryId].collectionIds.contains(collectionId)) {
            revert AutographErrors.CollectionNotFound();
        }

        if (_collections[collectionId].designer != msg.sender) {
            revert AutographErrors.AddressNotVerified();
        }

        for (uint256 i = 0; i < _collectionToNPCs[collectionId].length(); i++) {
            _npcToCollections[_collectionToNPCs[collectionId].at(i)].remove(
                collectionId
            );
        }

        delete _collectionToNPCs[collectionId];
        delete _collections[collectionId];

        _galleries[_galleryId].collectionIds.remove(collectionId);

        emit CollectionDeleted(collectionId, _galleryId);
    }

    function addCollections(
        AutographLibrary.CollectionInit[] memory colls,
        uint256 galleryId
    ) public onlyDesigner {
        if (_galleries[galleryId].designer != msg.sender) {
            revert AutographErrors.AddressNotVerified();
        }

        for (uint8 i = 0; i < colls.length; i++) {
            _collectionCounter++;

            _galleries[galleryId].collectionIds.add(_collectionCounter);

            _collections[_collectionCounter].galleryId = galleryId;
            _collections[_collectionCounter].galleryId = _collectionCounter;
            _collections[_collectionCounter].uri = colls[i].uri;
            _collections[_collectionCounter].amount = colls[i].amount;
            _collections[_collectionCounter].price = colls[i].price;
            _collections[_collectionCounter].collectionType = colls[i]
                .collectionType;

            for (uint8 j = 0; j < colls[i].acceptedTokens.length; j++) {
                _collections[_collectionCounter].acceptedTokens.add(
                    colls[i].acceptedTokens[j]
                );
            }

            for (uint8 j = 0; j < colls[i].npcs.length; j++) {
                _collections[_collectionCounter].npcs.add(colls[i].npcs[j]);
            }

            for (uint8 k = 0; k < colls[i].npcs.length; k++) {
                _npcToCollections[colls[i].npcs[k]].add(_collectionCounter);
                _collectionToNPCs[_collectionCounter].add(colls[i].npcs[k]);
            }
        }

        emit GalleryUpdated(msg.sender, galleryId);
    }

    function setTokenIdsToCollection(
        uint256[] memory tokenIds,
        uint256 collectionId
    ) external onlyMarket {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenIdToCollection[tokenIds[i]] = collectionId;
        }
    }

    function setAutographData(address _autographData) public onlyAdmin {
        autographData = AutographData(_autographData);
    }

    function setAutographMarket(address _autographMarket) public onlyAdmin {
        autographMarket = _autographMarket;
    }

    function setAutographAccessControl(
        address _autographAccessControl
    ) public onlyAdmin {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function getDesignerGalleries(
        address designer
    ) public view returns (uint256[] memory) {
        return _designerGalleries[designer].values();
    }

    function getCollectionDesigner(
        uint256 collectionId
    ) public view returns (address) {
        return _collections[collectionId].designer;
    }

    function getCollectionURI(
        uint256 collectionId
    ) public view returns (string memory) {
        return _collections[collectionId].uri;
    }

    function getCollectionAmount(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].amount;
    }

    function getCollectionPrice(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].price;
    }

    function getCollectionNPCs(
        uint256 collectionId
    ) public view returns (address[] memory) {
        return _collections[collectionId].npcs.values();
    }

    function getCollectionAcceptedTokens(
        uint256 collectionId
    ) public view returns (address[] memory) {
        return _collections[collectionId].acceptedTokens.values();
    }

    function getCollectionPubIds(
        uint256 collectionId
    ) public view returns (string[] memory) {
        return _collections[collectionId].postIds;
    }

    function getCollectionType(
        uint256 collectionId
    ) public view returns (AutographLibrary.AutographType) {
        return _collections[collectionId].collectionType;
    }

    function getMintedTokenIds(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].mintedTokenIds.values();
    }

    function getNPCToCollections(
        address npcWallet
    ) public view returns (uint256[] memory) {
        return _npcToCollections[npcWallet].values();
    }

    function getCollectionToNPCs(
        uint256 collectionId
    ) public view returns (address[] memory) {
        return _collectionToNPCs[collectionId].values();
    }

    function getCollectionURIByToken(
        uint256 tokenId
    ) public view returns (string memory) {
        return _collections[_tokenIdToCollection[tokenId]].uri;
    }

    function getGalleryURI(
        uint256 galleryId
    ) public view returns (string memory) {
        return _galleries[galleryId].uri;
    }

    function getGalleryDesigner(
        uint256 galleryId
    ) public view returns (address) {
        return _galleries[galleryId].designer;
    }

    function getGalleryCollectionIds(
        uint256 galleryId
    ) public view returns (uint256[] memory) {
        return _galleries[galleryId].collectionIds.values();
    }

    function getCollectionIsAcceptedToken(
        address token,
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].acceptedTokens.contains(token);
    }

    function getCollectionCounter() public view returns (uint256) {
        return _collectionCounter;
    }

    function getGalleryCounter() public view returns (uint256) {
        return _galleryCounter;
    }
}
