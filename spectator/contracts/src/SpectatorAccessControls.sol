// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;
import "./SpectatorErrors.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SpectatorAccessControls {
    string public symbol;
    string public name;
    address[] private _erc20s;
    address[] private _erc721s;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _agents;
    mapping(address => uint256) private _thresholdERC20;
    mapping(address => uint256) private _thresholdERC721;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event Threshhold20Added(address erc20, uint256 threshold);
    event Threshhold721Added(address erc721, uint256 threshold);
    event Threshhold20Removed(address erc20, uint256 threshold);
    event Threshhold721Removed(address erc721, uint256 threshold);

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert SpectatorErrors.OnlyAdmin();
        }
        _;
    }

    constructor() {
        _admins[msg.sender] = true;
        symbol = "SAC";
        name = "SpectatorAccessControls";
    }

    function addAdmin(address _admin) public onlyAdmin {
        if (_admins[_admin] || _admin == msg.sender) {
            revert SpectatorErrors.Existing();
        }
        _admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) public onlyAdmin {
        if (_admin == msg.sender) {
            revert SpectatorErrors.CantRemoveSelf();
        }
        if (!_admins[_admin]) {
            revert SpectatorErrors.AddressInvalid();
        }
        _admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function setERC20s(address[] memory erc20s) public onlyAdmin {
        _erc20s = erc20s;
    }

    function setERC721s(address[] memory erc721s) public onlyAdmin {
        _erc721s = erc721s;
    }

    function removeThresholdERC20(
        address erc20,
        uint256 threshold
    ) public onlyAdmin {
        delete _thresholdERC20[erc20];

        emit Threshhold20Removed(erc20, threshold);
    }

    function removeThresholdERC721(
        address erc721,
        uint256 threshold
    ) public onlyAdmin {
        delete _thresholdERC721[erc721];

        emit Threshhold721Removed(erc721, threshold);
    }

    function setThresholdERC20(
        address erc20,
        uint256 threshold
    ) public onlyAdmin {
        _thresholdERC20[erc20] = threshold;

        emit Threshhold20Added(erc20, threshold);
    }

    function setThresholdERC721(
        address erc721,
        uint256 threshold
    ) public onlyAdmin {
        _thresholdERC721[erc721] = threshold;

        emit Threshhold721Added(erc721, threshold);
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function getERC20s() public view returns (address[] memory) {
        return _erc20s;
    }

    function getERC721s() public view returns (address[] memory) {
        return _erc721s;
    }

    function getERC20Threshold(address erc20) public view returns (uint256) {
        return _thresholdERC20[erc20];
    }

    function getERC721Threshold(address erc721) public view returns (uint256) {
        return _thresholdERC721[erc721];
    }

    function isHolder(address holder) external view returns (bool) {
        bool _hasERC20 = false;
        bool _hasERC721 = false;

        for (uint256 i = 0; i < _erc20s.length; i++) {
            if (
                IERC20(_erc20s[i]).balanceOf(holder) >=
                _thresholdERC20[_erc20s[i]]
            ) {
                _hasERC20 = true;
                break;
            }
        }

        for (uint256 i = 0; i < _erc721s.length; i++) {
            if (
                IERC721(_erc721s[i]).balanceOf(holder) >=
                _thresholdERC721[_erc721s[i]]
            ) {
                _hasERC721 = true;
                break;
            }
        }

        return _hasERC20 && _hasERC721;
    }
}
