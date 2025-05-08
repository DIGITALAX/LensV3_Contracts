// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpectatorAccessControls.sol";
import "./SpectatorRewards.sol";

contract AU is ERC20 {
    SpectatorAccessControls public accessControls;
    SpectatorRewards public rewards;

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SpectatorErrors.OnlyAdmin();
        }
        _;
    }

    event SpectatorClaimed(address spectator, uint256 claim);

    constructor(address _accessControls) ERC20("Autonomy Units", "AU") {
        accessControls = SpectatorAccessControls(_accessControls);
    }

    function mintSpectator() public {
        uint256 _claim = rewards.getSpectatorAUToClaim(msg.sender);

        if (_claim <= 0) {
            revert SpectatorErrors.NoClaim();
        }

        rewards.updateSpectatorBalance(msg.sender, _claim);

        _mint(msg.sender, _claim);

        emit SpectatorClaimed(msg.sender, _claim);
    }

    function mint(address _to, uint256 _mintAmount) public onlyAdmin {
        _mint(_to, _mintAmount);
    }

    function setAccessControls(address _accessControls) public onlyAdmin {
        accessControls = SpectatorAccessControls(_accessControls);
    }

    function setRewards(address payable _rewards) public onlyAdmin {
        rewards = SpectatorRewards(_rewards);
    }
}
