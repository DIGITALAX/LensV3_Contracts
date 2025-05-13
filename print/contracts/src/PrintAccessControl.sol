// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "./PrintErrors.sol";

contract PrintAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _designers;
    mapping(address => bool) private _actions;
    mapping(address => bool) private _fulfillers;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event DesignerAdded(address indexed designer);
    event DesignerRemoved(address indexed designer);
    event ActionAdded(address indexed action);
    event ActionRemoved(address indexed action);
    event FulfillerAdded(address indexed fulfiller);
    event FulfillerRemoved(address indexed fulfiller);
    event CommunityStewardAdded(address indexed community);
    event CommunityStewardRemoved(address indexed community);

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert PrintErrors.AddressInvalid();
        }
        _;
    }

    constructor() {
        _admins[msg.sender] = true;
        symbol = "PAC";
        name = "PrintAccessControl";
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin] || admin == msg.sender) {
            revert PrintErrors.Existing();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (admin == msg.sender) {
            revert PrintErrors.CantRemoveSelf();
        }
        if (!_admins[admin]) {
            revert PrintErrors.AddressInvalid();
        }
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function addDesigner(address designer) external onlyAdmin {
        if (_designers[designer]) {
            revert PrintErrors.Existing();
        }
        _designers[designer] = true;
        emit DesignerAdded(designer);
    }

    function removeDesigner(address designer) external onlyAdmin {
        if (!_designers[designer]) {
            revert PrintErrors.AddressInvalid();
        }
        _designers[designer] = false;
        emit DesignerRemoved(designer);
    }

    function addAction(address action) external onlyAdmin {
        if (_actions[action]) {
            revert PrintErrors.Existing();
        }
        _actions[action] = true;
        emit ActionAdded(action);
    }

    function removeAction(address action) external onlyAdmin {
        if (!_actions[action]) {
            revert PrintErrors.AddressInvalid();
        }
        _actions[action] = false;
        emit ActionRemoved(action);
    }

    function addFulfiller(address fulfiller) external onlyAdmin {
        if (_fulfillers[fulfiller]) {
            revert PrintErrors.Existing();
        }
        _fulfillers[fulfiller] = true;
        emit FulfillerAdded(fulfiller);
    }

    function removeFulfiller(address fulfiller) external onlyAdmin {
        if (!_fulfillers[fulfiller]) {
            revert PrintErrors.AddressInvalid();
        }
        _fulfillers[fulfiller] = false;
        emit FulfillerRemoved(fulfiller);
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function isAction(address _address) public view returns (bool) {
        return _actions[_address];
    }

    function isDesigner(address _address) public view returns (bool) {
        return _designers[_address];
    }

    function isFulfiller(address _address) public view returns (bool) {
        return _fulfillers[_address];
    }
}
