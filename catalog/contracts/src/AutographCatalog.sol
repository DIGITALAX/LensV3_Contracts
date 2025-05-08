// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographLibrary.sol";
import "./AutographErrors.sol";
import "./AutographAccessControl.sol";

contract AutographCatalog {
    using EnumerableSet for EnumerableSet.AddressSet;

    AutographAccessControl public autographAccessControl;
    AutographLibrary.Autograph private _autograph;
    address public catalogNFT;

    modifier onlyAction() {
        if (!autographAccessControl.isAction(msg.sender)) {
            revert AutographErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!autographAccessControl.isAdmin(msg.sender)) {
            revert AutographErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyNFT() {
        if (msg.sender != catalogNFT) {
            revert AutographErrors.AddressInvalid();
        }
        _;
    }

    event AutographCreated(string uri, uint256 amount);
    event AutographTokensMinted(uint16 amount);

    constructor(address _autographAccessControl, address _catalogNFT) {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
        catalogNFT = _catalogNFT;
    }

    function createAutograph(
        AutographLibrary.AutographInit memory autograph
    ) external onlyAction {
        _autograph.uri = autograph.uri;
        _autograph.amount = autograph.amount;
        _autograph.price = autograph.price;
        _autograph.designer = autograph.designer;
        _autograph.postId = autograph.postId;
        _autograph.pages = autograph.pages;
        _autograph.pageCount = autograph.pageCount;

        for (uint8 i = 0; i < autograph.acceptedTokens.length; i++) {
            _autograph.acceptedTokens.add(autograph.acceptedTokens[i]);
        }

        emit AutographCreated(autograph.uri, autograph.amount);
    }

    function setMintedCatalog(uint16 amount) external onlyNFT {
        _autograph.minted += amount;

        emit AutographTokensMinted(amount);
    }

    function setAutographAccessControl(
        address _autographAccessControl
    ) public onlyAdmin {
        autographAccessControl = AutographAccessControl(
            _autographAccessControl
        );
    }

    function setCatalogNFT(address _catalogNFT) public onlyAdmin {
        catalogNFT = _catalogNFT;
    }

    function getAutographURI() public view returns (string memory) {
        return _autograph.uri;
    }

    function getAutographAmount() public view returns (uint256) {
        return _autograph.amount;
    }

    function getAutographPrice() public view returns (uint256) {
        return _autograph.price;
    }

    function getAutographPageCount() public view returns (uint8) {
        return _autograph.pageCount;
    }

    function getAutographPage(
        uint256 page
    ) public view returns (string memory) {
        return _autograph.pages[page - 1];
    }

    function getAutographAcceptedTokens()
        public
        view
        returns (address[] memory)
    {
        return _autograph.acceptedTokens.values();
    }

    function isAcceptedToken(address token) public view returns (bool) {
        return _autograph.acceptedTokens.contains(token);
    }

    function getAutographPostId() public view returns (uint256) {
        return _autograph.postId;
    }

    function getAutographDesigner() public view returns (address) {
        return _autograph.designer;
    }

    function getAutographMinted() public view returns (uint256) {
        return _autograph.minted;
    }
}
