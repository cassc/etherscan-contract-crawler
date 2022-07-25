// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

pragma solidity ^0.8.0;

interface IRaid {
    function claimRewards(address user) external;
}

contract RaidPartyCollector {
    IERC20 public immutable CTFI = IERC20(0xCfef8857E9C80e3440A823971420F7Fa5F62f020);
    IRaid public immutable RAID = IRaid(0xFa209a705a4DA0A240AA355c889ed0995154D7Eb);

    function collect(address[] calldata wallets) external {
        RAID.claimRewards(msg.sender);
        for (uint256 i = 0; i < wallets.length;) {
            address wallet = wallets[i];
            RAID.claimRewards(wallet);
            uint balance = CTFI.balanceOf(wallet);
            CTFI.transferFrom(wallet, msg.sender, balance);
            unchecked{ ++i; }
        }
    }

}