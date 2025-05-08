// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AutographAccessControl.sol";
import "./AutographCollections.sol";
import "./AutographErrors.sol";

contract AutographNFT is ERC721Enumerable {
    AutographAccessControl public autographAccessControl;
    AutographCollections public autographCollections;
    address public autographMarket;
    uint256 private _supply;

    event CollectionsTokenMinted(address purchaser, uint256[] tokenIds);

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

    function mintCollection(
        address buyer,
        uint8 amount
    ) public onlyMarket returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](amount);

        for (uint8 i = 0; i < amount; i++) {
            _supply++;
            _safeMint(buyer, _supply);
            tokenIds[i] = _supply;
        }

        emit CollectionsTokenMinted(buyer, tokenIds);

        return tokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return autographCollections.getCollectionURIByToken(tokenId);
    }

    function setAutographCollections(
        address _autographCollections
    ) public onlyAdmin {
        autographCollections = AutographCollections(_autographCollections);
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
