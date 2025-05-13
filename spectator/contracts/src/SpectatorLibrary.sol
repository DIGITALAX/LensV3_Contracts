// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.26;

contract SpectatorLibrary {
    struct SpectatorActivity {
        string data;
        address agent;
        uint256 blocktimestamp;
    }

    struct Spectator {
        uint256 initialization;
        uint256 auEarned;
        uint256 auClaimed;
        uint256 auToClaim;
    }

 
}
