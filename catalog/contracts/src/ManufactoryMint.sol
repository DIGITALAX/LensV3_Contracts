// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ManufactoryMint is ERC721("ManufactoryMint", "FACT") {
    string private _uri;
    uint256 private _totalSupply;

    error AlreadyMinted();

    mapping(address => bool) private _hasMinted;

    event TokenMinted(uint256 indexed tokenId, address minterAddress);

    modifier uniqueMinter() {
        if (_hasMinted[msg.sender]) {
            revert AlreadyMinted();
        }
        _;
    }

    constructor(string memory uri) {
        _totalSupply = 0;
        _uri = uri;
    }

    function mint() public uniqueMinter {
        _hasMinted[msg.sender] = true;

        _totalSupply++;

        _safeMint(msg.sender, _totalSupply);

        emit TokenMinted(_totalSupply, msg.sender);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        return _uri;
    }

    function hasMinted(address _address) public view returns (bool) {
        return _hasMinted[_address];
    }

    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
