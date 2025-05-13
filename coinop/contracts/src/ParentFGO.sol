// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./FGOAccessControl.sol";
import "./FGOLibrary.sol";
import "./ChildFGO.sol";

contract ParentFGO is ERC721 {
    ChildFGO public childFGO;
    FGOAccessControl public accessControl;
    address public market;
    uint256 private _supply;
    uint256 private _parentSupply;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyMarket() {
        if (msg.sender != market) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    mapping(uint256 => FGOLibrary.ParentMetadata) private _parentTokens;
    mapping(uint256 => uint256) private _tokenIdToParent;

    event ParentCreated(uint256 parentId);
    event ParentWithChildrenMinted(uint256 tokenId, uint256 parentId);

    constructor(
        address _childFGO,
        address _accessControl
    ) ERC721("ParentFGO", "PFGO") {
        childFGO = ChildFGO(_childFGO);
        accessControl = FGOAccessControl(_accessControl);
    }

    function createParentFGO(
        FGOLibrary.ParentMetadata memory params
    ) public onlyAdmin {
        _parentSupply++;

        _parentTokens[_parentSupply] = params;

        emit ParentCreated(_parentSupply);
    }

    function mintParentWithChildren(
        address buyer,
        uint256 parentId
    ) external onlyMarket returns (uint256) {
        if (_parentTokens[parentId].childIds.length < 1) {
            revert FGOErrors.InvalidAmount();
        }
        _supply++;
        _mint(buyer, _supply);
        _tokenIdToParent[_supply] = parentId;

        for (uint8 i = 0; i < _parentTokens[parentId].childIds.length; i++) {
            childFGO.mintWithURI(buyer, _parentTokens[parentId].childIds[i]);
        }

        emit ParentWithChildrenMinted(_supply, parentId);

        return _supply;
    }

    function burnParent(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId)) {
            revert FGOErrors.AddressInvalid();
        }

        for (
            uint256 i = 0;
            i < _parentTokens[_tokenIdToParent[tokenId]].childIds.length;
            i++
        ) {
            childFGO.burn(
                msg.sender,
                _parentTokens[_tokenIdToParent[tokenId]].childIds[i]
            );
        }

        _burn(tokenId);

        delete _tokenIdToParent[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (msg.sender != ownerOf(tokenId)) {
            revert FGOErrors.AddressInvalid();
        }

        _transferWithChildren(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (msg.sender != ownerOf(tokenId)) {
            revert FGOErrors.AddressInvalid();
        }

        _transferWithChildren(from, to, tokenId);
    }

    function _transferWithChildren(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint256 parentId = _tokenIdToParent[tokenId];

        for (uint256 i = 0; i < _parentTokens[parentId].childIds.length; i++) {
            uint256 childId = _parentTokens[parentId].childIds[i];
            childFGO.safeTransferFrom(from, to, childId, 1, "");
        }

        _transfer(from, to, tokenId);
    }

    function setChildFGO(address _childFGO) public onlyAdmin {
        childFGO = ChildFGO(_childFGO);
    }

    function setAccessControl(address _accessControl) public onlyAdmin {
        accessControl = FGOAccessControl(_accessControl);
    }

    function setMarket(address _market) public onlyAdmin {
        market = _market;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _parentTokens[_tokenIdToParent[tokenId]].uri;
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }

    function getParentSupply() public view returns (uint256) {
        return _parentSupply;
    }

    function getParentURI(
        uint256 parentId
    ) public view returns (string memory) {
        return _parentTokens[parentId].uri;
    }

    function getParentPoster(
        uint256 parentId
    ) public view returns (string memory) {
        return _parentTokens[parentId].poster;
    }

    function getParentChildIds(
        uint256 parentId
    ) public view returns (uint256[] memory) {
        return _parentTokens[parentId].childIds;
    }

    function getParentPrice(uint256 parentId) public view returns (uint256) {
        return _parentTokens[parentId].price;
    }

    function getParentPrintType(uint256 parentId) public view returns (uint8) {
        return _parentTokens[parentId].printType;
    }

    function getTokenIdToParent(uint256 tokenId) public view returns (uint256) {
        return _tokenIdToParent[tokenId];
    }
}
