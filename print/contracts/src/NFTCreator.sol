// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./PrintDesignData.sol";
import "./CollectionCreator.sol";
import "./PrintAccessControl.sol";
import "./PrintLibrary.sol";
import "./PrintErrors.sol";

contract NFTCreator is ERC721Enumerable {
    CollectionCreator public collectionCreator;
    PrintDesignData public printData;
    PrintAccessControl public printAccessControl;

    event BatchTokenMinted(address indexed to, uint256[] tokenIds);

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.AddressNotAdmin();
        }
        _;
    }

    constructor(
        address printDataAddress,
        address printAccessControlAddress
    ) ERC721("NFTCreator", "NFTC") {
        printData = PrintDesignData(printDataAddress);
        printAccessControl = PrintAccessControl(printAccessControlAddress);
    }

    function mintBatch(
        string memory uri,
        address purchaserAddress,
        address chosenCurrency,
        uint256 amount,
        uint256 collectionId,
        uint256 chosenIndex
    ) public {
        if (msg.sender != address(collectionCreator)) {
            revert PrintErrors.OnlyCollectionCreator();
        }
        uint256[] memory _tokenIds = new uint256[](amount);
        uint256 _supply = printData.getTokenSupply();
        for (uint256 i = 0; i < amount; i++) {
            PrintLibrary.Token memory newToken = PrintLibrary.Token({
                uri: uri,
                chosenCurrency: chosenCurrency,
                tokenId: _supply + i + 1,
                collectionId: collectionId,
                index: chosenIndex
            });
            _safeMint(purchaserAddress, _supply + i + 1);
            printData.setNFT(newToken);
            _tokenIds[i] = _supply + i + 1;
        }

        emit BatchTokenMinted(purchaserAddress, _tokenIds);
    }

    function burnBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                msg.sender == ownerOf(tokenIds[i]),
                "ERC721Metadata: Only token owner can burn tokens"
            );
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId),
            "ERC721Metadata: Only token owner can burn token"
        );
        _burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return printData.getTokenURI(tokenId);
    }

    function setPrintDesignDataAddress(
        address newPrintDesignDataAddress
    ) public onlyAdmin {
        printData = PrintDesignData(newPrintDesignDataAddress);
    }

    function setCollectionCreatorAddress(
        address newCollectionCreatorAddress
    ) public onlyAdmin {
        collectionCreator = CollectionCreator(newCollectionCreatorAddress);
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }
}
