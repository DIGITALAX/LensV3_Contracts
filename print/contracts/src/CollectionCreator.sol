// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "./NFTCreator.sol";
import "./PrintDesignData.sol";
import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./PrintSplitsData.sol";
import "./PrintErrors.sol";

contract CollectionCreator {
    PrintDesignData public printDesignData;
    PrintAccessControl public printAccessControl;
    NFTCreator public nftCreator;
    PrintSplitsData public printSplitsData;
    string public symbol;
    string public name;
    address public marketCreator;

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

    constructor(
        address nftCreatorAddress,
        address printDesignDataAddress,
        address printAccessControlAddress,
        address printSplitsDataAddress
    ) {
        nftCreator = NFTCreator(nftCreatorAddress);
        printDesignData = PrintDesignData(printDesignDataAddress);
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        printSplitsData = PrintSplitsData(printSplitsDataAddress);
        symbol = "CCR";
        name = "CollectionCreator";
    }

    function createCollection(
        PrintLibrary.MintParams memory params
    ) external returns (uint256) {
        if (
            !printAccessControl.isDesigner(msg.sender) &&
            !printAccessControl.isOpenAction(msg.sender) &&
            !printAccessControl.isDesigner(params.creator)
        ) {
            revert PrintErrors.AddressNotDesigner();
        }

        for (uint256 k = 0; k < params.acceptedTokens.length; k++) {
            if (!printSplitsData.getIsCurrency(params.acceptedTokens[k])) {
                revert PrintErrors.InvalidCurrency();
            }
        }

        uint256 _amount = params.amount;
        if (params.unlimited) {
            _amount = type(uint256).max;
        }
        PrintLibrary.Collection memory newCollection = PrintLibrary.Collection({
            collectionId: printDesignData.getCollectionSupply() + 1,
            prices: params.prices,
            acceptedTokens: params.acceptedTokens,
            communityIds: params.communityIds,
            amount: _amount,
            postId: params.postId,
            dropId: params.dropId,
            tokenIds: new uint256[](0),
            mintedTokens: 0,
            fulfiller: params.fulfiller,
            creator: params.creator,
            uri: params.uri,
            printType: params.printType,
            origin: params.origin,
            unlimited: params.unlimited,
            encrypted: params.encrypted
        });

        uint256 _collectionId = printDesignData.setCollection(newCollection);
        string memory _uri = printDesignData.getDropURI(params.dropId);
        uint256[] memory _collectionIds = printDesignData.getDropCollectionIds(
            params.dropId
        );
        uint256[] memory _newCollectionIds = new uint256[](
            _collectionIds.length + 1
        );
        for (uint i = 0; i < _collectionIds.length; i++) {
            _newCollectionIds[i] = _collectionIds[i];
        }
        _newCollectionIds[_collectionIds.length] = _collectionId;

        _internalUpdate(_newCollectionIds, _uri, params.creator, params.dropId);

        return _collectionId;
    }

    function purchaseAndMintToken(
        uint256[] memory collectionIds,
        uint256[] memory amounts,
        uint256[] memory chosenIndexes,
        address purchaserAddress,
        address chosenCurrency
    ) external {
        if (msg.sender != marketCreator) {
            revert PrintErrors.AddressNotMarket();
        }
        uint256 _initialSupply = printDesignData.getTokenSupply();

        for (uint256 i = 0; i < collectionIds.length; i++) {
            nftCreator.mintBatch(
                printDesignData.getCollectionURI(collectionIds[i]),
                purchaserAddress,
                chosenCurrency,
                amounts[i],
                collectionIds[i],
                chosenIndexes[i]
            );

            uint256[] memory _newTokenIds = new uint256[](amounts[i]);
            uint256 _mintedTokens = 0;
            for (uint256 j = 0; j < amounts[i]; j++) {
                uint256 tokenId = _initialSupply + j + 1;
                _newTokenIds[j] = tokenId;
                _mintedTokens++;
            }

            printDesignData.setCollectionMintedTokens(
                collectionIds[i],
                _mintedTokens
            );
            printDesignData.setCollectionTokenIds(
                _newTokenIds,
                collectionIds[i]
            );
        }
    }

    function removeCollection(uint256 collectionId) public onlyDesigner {
        if (printDesignData.getCollectionCreator(collectionId) != msg.sender) {
            revert PrintErrors.AddressNotDesigner();
        }

        if (printDesignData.getCollectionTokensMinted(collectionId) > 0) {
            revert PrintErrors.InvalidRemoval();
        }

        uint256 _dropId = printDesignData.getCollectionDropId(collectionId);
        uint256[] memory _collectionIds = printDesignData.getDropCollectionIds(
            _dropId
        );
        string memory _uri = printDesignData.getDropURI(_dropId);
        uint256[] memory _newIds = new uint256[](_collectionIds.length - 1);
        uint256 j = 0;

        for (uint256 i = 0; i < _collectionIds.length; i++) {
            if (_collectionIds[i] != collectionId) {
                _newIds[j] = _collectionIds[i];
                j++;
            }
        }

        printDesignData.modifyCollectionsInDrop(_newIds, _uri, _dropId);

        printDesignData.deleteCollection(collectionId);
    }

    function createDrop(string memory _uri) public onlyDesigner {
        printDesignData.createDrop(_uri, msg.sender);
    }

    function updateDrop(
        uint256[] memory collectionIds,
        string memory uri,
        uint256 dropId
    ) public {
        if (bytes(printDesignData.getDropURI(dropId)).length == 0) {
            revert PrintErrors.InvalidUpdate();
        }

        if (printDesignData.getDropCreator(dropId) != msg.sender) {
            revert PrintErrors.InvalidUpdate();
        }

        for (uint256 i = 0; i < collectionIds.length; i++) {
            if (
                printDesignData.getCollectionCreator(collectionIds[i]) !=
                msg.sender
            ) {
                revert PrintErrors.AddressNotDesigner();
            }
        }

        printDesignData.modifyCollectionsInDrop(collectionIds, uri, dropId);
    }

    function removeDrop(uint256 dropId) public onlyDesigner {
        if (
            bytes(printDesignData.getDropURI(dropId)).length == 0 ||
            printDesignData.getDropCreator(dropId) != msg.sender
        ) {
            revert PrintErrors.InvalidUpdate();
        }
        printDesignData.deleteDrop(dropId);
    }

    function setPrintDesignDataAddress(
        address newPrintDesignDataAddress
    ) public onlyAdmin {
        printDesignData = PrintDesignData(newPrintDesignDataAddress);
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

    function setNFTCreatorAddress(
        address newNFTCreatorAddress
    ) public onlyAdmin {
        nftCreator = NFTCreator(newNFTCreatorAddress);
    }

    function setMarketCreatorAddress(
        address newMarketCreatorAddress
    ) public onlyAdmin {
        marketCreator = newMarketCreatorAddress;
    }

    function _internalUpdate(
        uint256[] memory collectionIds,
        string memory uri,
        address caller,
        uint256 dropId
    ) internal {
        if (bytes(printDesignData.getDropURI(dropId)).length == 0) {
            revert PrintErrors.InvalidUpdate();
        }
        if (printDesignData.getDropCreator(dropId) != caller) {
            revert PrintErrors.InvalidUpdate();
        }

        for (uint256 i = 0; i < collectionIds.length; i++) {
            if (
                printDesignData.getCollectionCreator(collectionIds[i]) != caller
            ) {
                revert PrintErrors.AddressNotDesigner();
            }
        }

        printDesignData.modifyCollectionsInDrop(collectionIds, uri, dropId);
    }
}
