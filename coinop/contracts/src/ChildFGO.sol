// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./FGOAccessControl.sol";
import "./FGOLibrary.sol";

contract ChildFGO is ERC1155 {
    FGOAccessControl public accessControl;
    address public parentFGO;
    mapping(uint256 => FGOLibrary.ChildMetadata) private _childTokens;
    uint256 private _supply;

    modifier onlyAdmin() {
        if (!accessControl.isAdmin(msg.sender)) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyParent() {
        if (msg.sender != parentFGO) {
            revert FGOErrors.AddressInvalid();
        }

        _;
    }

    event ChildCreated(uint256 childId);
    event ChildMinted(uint256 childId);

    constructor(address _accessControl) ERC1155("") {
        accessControl = FGOAccessControl(_accessControl);
    }

    function createChildFGO(
        FGOLibrary.ChildMetadata memory params
    ) public onlyAdmin {
        _supply++;

        _childTokens[_supply] = params;

        emit ChildCreated(_supply);
    }

    function mintWithURI(address to, uint256 childId) external onlyParent {
        if (bytes(_childTokens[childId].uri).length == 0) {
            revert FGOErrors.InvalidChild();
        }

        _mint(to, childId, 1, "");

        emit ChildMinted(childId);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _childTokens[id].uri;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (msg.sender != parentFGO) {
            revert FGOErrors.AddressInvalid();
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (msg.sender != parentFGO) {
            revert FGOErrors.AddressInvalid();
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function burn(address from, uint256 id) external onlyParent {
        _burn(from, id, 1);
    }

    function setParentFGO(address _parentFGO) public onlyAdmin {
        parentFGO = _parentFGO;
    }

    function setAccessControl(address _accessControl) public onlyAdmin {
        accessControl = FGOAccessControl(_accessControl);
    }

    function getTokenSupply() public view returns (uint256) {
        return _supply;
    }

    function getChildURI(uint256 id) public view returns (string memory) {
        return _childTokens[id].uri;
    }

    function getChildPrice(uint256 id) public view returns (uint256) {
        return _childTokens[id].price;
    }
}
