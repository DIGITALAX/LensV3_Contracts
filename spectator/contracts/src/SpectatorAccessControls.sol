// SPDX-License-Identifier: UNLICENSE

pragma solidity 0.8.24;
import "./SpectatorErrors.sol";

contract SpectatorAccessControls {
    string public symbol;
    string public name;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _agents;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);

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

    function addAgent(address agent) external onlyAdmin {
        if (_agents[agent]) {
            revert SpectatorErrors.AgentAlreadyExists();
        }
        _agents[agent] = true;
        emit AgentAdded(agent);
    }

    function removeAgent(address agent) external onlyAdmin {
        if (!_agents[agent]) {
            revert SpectatorErrors.AgentDoesntExist();
        }

        _agents[agent] = false;
        emit AgentRemoved(agent);
    }

    function isAdmin(address _address) public view returns (bool) {
        return _admins[_address];
    }

    function isAgent(address _address) public view returns (bool) {
        return _agents[_address];
    }
}
