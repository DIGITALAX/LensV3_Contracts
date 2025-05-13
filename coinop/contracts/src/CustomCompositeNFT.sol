// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./FGOAccessControl.sol";

contract CustomCompositeNFT is ERC721Enumerable {
    FGOAccessControl public accessControl;
    address public market;
    uint256 private _supply;

    mapping(uint256 => string) private _tokenIdURI;

    event TokenMinted(address buyer, uint256 tokenId);

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyMarket() {
        if (market != msg.sender) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    constructor(address _accessControl) ERC721("CustomCompositeNFT", "POSE") {
        accessControl = FGOAccessControl(_accessControl);
    }

    function mint(
        string memory _uri,
        address buyer
    ) public onlyMarket returns (uint256) {
        _supply++;

        _safeMint(buyer, _supply);
        _tokenIdURI[_supply] = _uri;

        emit TokenMinted(buyer, _supply);

        return _supply;
    }

    function setMarket(address _market) public onlyAdmin {
        market = _market;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return _tokenIdURI[_tokenId];
    }

    function getSupplyCount() public view returns (uint256) {
        return _supply;
    }
}
