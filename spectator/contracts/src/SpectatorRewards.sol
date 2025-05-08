// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.26;

import "./SpectatorAccessControls.sol";
import "./SpectatorLibrary.sol";
import "./SpectatorErrors.sol";
import "./skyhunters/SkyhuntersAccessControls.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SpectatorRewards {
    using EnumerableSet for EnumerableSet.AddressSet;

    SpectatorAccessControls public accessControls;
    SkyhuntersAccessControls public skyhuntersAccessControls;
    address public au;

    mapping(address => SpectatorLibrary.SpectatorActivity[])
        private _spectatorActivity;
    mapping(address => SpectatorLibrary.Spectator) private _spectators;
    mapping(address => EnumerableSet.AddressSet) private _agentCycleSpectators;
    mapping(address => uint256) private _agentAu;
    mapping(address => uint256) private _agentAuTotal;

    event Spectated(string data, address spectator, uint256 count);
    event AgentAUUpdated(address agent, uint256 au);
    event SpectatorBalanceUpdated(address spectator, uint256 balance);
    event AgentPaidAU(address agent, uint256 amount);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SpectatorErrors.OnlyAdmin();
        }
        _;
    }

    modifier onlyAdminOrAgent() {
        if (
            !accessControls.isAdmin(msg.sender) &&
            !skyhuntersAccessControls.isAgent(msg.sender)
        ) {
            revert SpectatorErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyAdminOrAU() {
        if (!accessControls.isAdmin(msg.sender) && au != msg.sender) {
            revert SpectatorErrors.AddressInvalid();
        }
        _;
    }

    modifier onlyHolderOrAgent() {
        if (
            !accessControls.isHolder(msg.sender) &&
            !skyhuntersAccessControls.isAgent(msg.sender)
        ) {
            revert SpectatorErrors.InvalidTokens();
        }
        _;
    }

    modifier onlyAgent() {
        if (!skyhuntersAccessControls.isAgent(msg.sender)) {
            revert SpectatorErrors.AddressInvalid();
        }
        _;
    }

    constructor(
        address _accessControls,
        address _au,
        address payable _skyhuntersAccessControls
    ) {
        accessControls = SpectatorAccessControls(_accessControls);
        au = _au;
        skyhuntersAccessControls = SkyhuntersAccessControls(
            _skyhuntersAccessControls
        );
    }

    function spectate(
        string memory data,
        address agent
    ) public onlyHolderOrAgent {
        if (_spectators[msg.sender].initialization == 0) {
            _spectators[msg.sender] = SpectatorLibrary.Spectator({
                initialization: block.timestamp,
                auEarned: 0,
                auClaimed: 0,
                auToClaim: 0
            });
        }
        _spectatorActivity[msg.sender].push(
            SpectatorLibrary.SpectatorActivity({
                blocktimestamp: block.timestamp,
                data: data,
                agent: agent
            })
        );
        _agentCycleSpectators[agent].add(msg.sender);

        emit Spectated(data, msg.sender, _spectatorActivity[msg.sender].length);
    }

    function addAgentAU(
        address agent,
        uint256 balance
    ) public onlyAdminOrAgent {
        _agentAu[agent] += balance;
        _agentAuTotal[agent] += balance;

        emit AgentAUUpdated(agent, balance);
    }

    function agentPayAU() public onlyAgent {
        uint256 _cycleLength = _agentCycleSpectators[msg.sender].length();
        uint256 _totalAU = _agentAu[msg.sender];
        uint256 _perSpectator = _totalAU / _cycleLength;
        uint256 _distributedAU = _perSpectator * _cycleLength;
        uint256 _residue = _totalAU - _distributedAU;

        for (uint256 i = 0; i < _cycleLength; i++) {
            address spectator = _agentCycleSpectators[msg.sender].at(i);
            _spectators[spectator].auToClaim += _perSpectator;
            _spectators[spectator].auEarned += _perSpectator;
        }

        delete _agentCycleSpectators[msg.sender];

        emit AgentPaidAU(msg.sender, _agentAu[msg.sender]);

        _agentAu[msg.sender] = _residue;
    }

    function updateSpectatorBalance(
        address spectator,
        uint256 balance
    ) public onlyAdminOrAU {
        if (balance < _spectators[spectator].auToClaim) {
            revert SpectatorErrors.BalanceInvalid();
        }

        _spectators[spectator].auToClaim -= balance;
        _spectators[spectator].auClaimed += balance;

        emit SpectatorBalanceUpdated(spectator, balance);
    }

    function getSpectatorCount(
        address spectator
    ) public view returns (uint256) {
        return _spectatorActivity[spectator].length;
    }

    function getSpectatorTimestamp(
        address spectator,
        uint256 count
    ) public view returns (uint256) {
        return _spectatorActivity[spectator][count].blocktimestamp;
    }

    function getSpectatorAgent(
        address spectator,
        uint256 count
    ) public view returns (address) {
        return _spectatorActivity[spectator][count].agent;
    }

    function getSpectatorData(
        address spectator,
        uint256 count
    ) public view returns (string memory) {
        return _spectatorActivity[spectator][count].data;
    }

    function getAgentCycleSpectators(
        address agent
    ) public view returns (address[] memory) {
        return _agentCycleSpectators[agent].values();
    }

    function getIsCycleSpectator(
        address agent,
        address spectator
    ) public view returns (bool) {
        return _agentCycleSpectators[agent].contains(spectator);
    }

    function getSpectatorAUEarned(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].auEarned;
    }

    function getSpectatorAUClaimed(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].auClaimed;
    }

    function getSpectatorAUToClaim(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].auToClaim;
    }

    function getSpectatorInitialization(
        address spectator
    ) public view returns (uint256) {
        return _spectators[spectator].initialization;
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SpectatorAccessControls(_accessControls);
    }

    function getAgentAUTotal(address agent) public view returns (uint256) {
        return _agentAuTotal[agent];
    }

    function getAgentAUCurrent(address agent) public view returns (uint256) {
        return _agentAu[agent];
    }

    function setSkyhuntersAccessControls(
        address payable _skyhuntersAccessControls
    ) public onlyAdmin {
        skyhuntersAccessControls = SkyhuntersAccessControls(
            _skyhuntersAccessControls
        );
    }

    function setAU(address _au) public onlyAdmin {
        au = _au;
    }

    function emergencyWithdraw(
        uint256 amount,
        uint256 gasAmount
    ) external onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: amount,
            gas: gasAmount
        }("");
        if (!success) {
            revert SpectatorErrors.TransferFailed();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
