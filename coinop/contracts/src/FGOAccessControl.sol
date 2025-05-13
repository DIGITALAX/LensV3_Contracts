// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;
import "./FGOErrors.sol";

contract FGOAccessControl {
    string public symbol;
    string public name;
    address private _fulfiller;

    mapping(address => bool) private _admins;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert FGOErrors.AddressInvalid();
        }
        _;
    }

    constructor() {
        _admins[msg.sender] = true;
        symbol = "FGOAC";
        name = "FGOAccessControl";
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin] || admin == msg.sender) {
            revert FGOErrors.Existing();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (admin == msg.sender) {
            revert FGOErrors.CantRemoveSelf();
        }
        if (!_admins[admin]) {
            revert FGOErrors.AddressInvalid();
        }
        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function setFulfiller(address fulfiller) public onlyAdmin {
        _fulfiller = fulfiller;
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function getFulfiller() public view returns (address) {
        return _fulfiller;
    }
}
