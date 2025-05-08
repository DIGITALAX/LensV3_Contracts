// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./AutographCatalog.sol";
import "./AutographErrors.sol";

contract CatalogNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    AutographCatalog public autographCatalog;
    address public autographMarket;
    uint256 private _supply;

    event BatchTokenMinted(address purchaser, uint256[] tokenIds);

    modifier onlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyMarket() {
        if (msg.sender != autographMarket) {
            revert AutographErrors.AddressNotVerified();
        }
        _;
    }

    constructor(
        address _autographAccessControlAddress
    ) ERC721("AutographNFT", "CNFT") {
        autographAccessControl = AutographAccessControl(
            _autographAccessControlAddress
        );
    }

    function mintBatch(
        address buyer,
        uint8 amount
    ) public onlyMarket returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](amount);

        for (uint8 i = 0; i < amount; i++) {
            _supply++;
            _safeMint(buyer, _supply);
            tokenIds[i] = _supply;
        }

        autographCatalog.setMintedCatalog(amount);

        emit BatchTokenMinted(buyer, tokenIds);

        return tokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return autographCatalog.getAutographURI();
    }

    function setAutographCatalog(address _autographCatalog) public onlyAdmin {
        autographCatalog = AutographCatalog(_autographCatalog);
    }

    function setAutographAccessControl(
        address _autographAccessControl
    ) public onlyAdmin {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function setAutographMarket(address _autographMarket) public onlyAdmin {
        autographMarket = _autographMarket;
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }
}
