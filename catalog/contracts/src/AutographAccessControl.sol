// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./AutographErrors.sol";

contract AutographAccessControl {
    string public symbol;
    string public name;
    address public fulfiller;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _designers;
    mapping(address => bool) private _actions;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event DesignerAdded(address indexed designer);
    event DesignerRemoved(address indexed designer);
    event ActionAdded(address indexed action);
    event ActionRemoved(address indexed action);
    event FulfillerAdded(address indexed action);
    event FulfillerRemoved(address indexed action);

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert AutographErrors.AddressInvalid();
        }
        _;
    }

    constructor() {
        _admins[msg.sender] = true;
        symbol = "AAC";
        name = "AutographAccessControl";
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin] || admin == msg.sender) {
            revert AutographErrors.Existing();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (admin == msg.sender) {
            revert AutographErrors.CantRemoveSelf();
        }
        if (!_admins[admin]) {
            revert AutographErrors.AddressInvalid();
        }
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function addDesigner(address designer) external onlyAdmin {
        if (_designers[designer]) {
            revert AutographErrors.Existing();
        }
        _designers[designer] = true;
        emit DesignerAdded(designer);
    }

    function removeDesigner(address designer) public onlyAdmin {
        if (!_designers[designer]) {
            revert AutographErrors.AddressInvalid();
        }
        _designers[designer] = false;
        emit DesignerRemoved(designer);
    }

    function addAction(address action) public onlyAdmin {
        if (_actions[action]) {
            revert AutographErrors.Existing();
        }
        _actions[action] = true;
        emit ActionAdded(action);
    }

    function removeOpenAction(address action) public onlyAdmin {
        if (!_actions[action]) {
            revert AutographErrors.AddressInvalid();
        }
        _actions[action] = false;
        emit ActionRemoved(action);
    }

    function setFulfiller(address _fulfiller) public onlyAdmin {
        fulfiller = _fulfiller;
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function isDesigner(address _address) public view returns (bool) {
        return _designers[_address];
    }

    function isAction(address _address) public view returns (bool) {
        return _actions[_address];
    }
}
