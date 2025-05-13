// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./NFTCreator.sol";
import "./PrintAccessControl.sol";
import "./CollectionCreator.sol";

contract PrintNFT is ERC721Enumerable {
    CollectionCreator public collectionCreator;
    PrintAccessControl public printAccessControl;
    address public nftCreator;

    uint256 internal _tokenSupply;
    uint8 internal _origin;

    modifier onlyAdmin() {
        if (!printAccessControl.isAdmin(msg.sender)) {
            revert PrintErrors.AddressNotAdmin();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address printAccessControlAddress,
        uint8 origin
    ) ERC721(name, symbol) {
        _origin = origin;
        printAccessControl = PrintAccessControl(printAccessControlAddress);
        _tokenSupply = 0;
    }

    function mintBatch(
        address buyer,
        uint256 amount
    ) public returns (uint256[] memory) {
        if (msg.sender != nftCreator) {
            revert PrintErrors.OnlyNFTCreator();
        }
        uint256[] memory _tokenIds = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply++;
            _safeMint(buyer, _tokenSupply);
            _tokenIds[i] = _tokenSupply;
        }

        return _tokenIds;
    }

    function burnBatch(uint256[] memory tokenIds) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (msg.sender != ownerOf(tokenIds[i])) {
                revert PrintErrors.NotOwner();
            }
            burn(tokenIds[i]);
        }
    }

    function burn(uint256 tokenId) public virtual {
        if (msg.sender != ownerOf(tokenId)) {
            revert PrintErrors.NotOwner();
        }

        _burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return collectionCreator.getTokenURI(tokenId, _origin);
    }

    function setCollectionCreatorAddress(
        address newPrintDesignDataAddress
    ) public virtual onlyAdmin {
        collectionCreator = CollectionCreator(newPrintDesignDataAddress);
    }

    function setNFTCreator(address _nftCreator) public virtual onlyAdmin {
        nftCreator = _nftCreator;
    }

    function setPrintAccessControlAddress(
        address newPrintAccessControlAddress
    ) public virtual onlyAdmin {
        printAccessControl = PrintAccessControl(newPrintAccessControlAddress);
    }

    function getTokenSupply() public view virtual returns (uint256) {
        return _tokenSupply;
    }

    function getOrigin() public view virtual returns (uint8) {
        return _origin;
    }
}
