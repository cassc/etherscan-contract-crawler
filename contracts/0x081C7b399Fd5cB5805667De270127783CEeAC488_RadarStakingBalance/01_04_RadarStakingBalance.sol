// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.17;

// Author: @mizi

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/iRadarStake.sol";

contract RadarStakingBalance is Ownable {

    constructor() {}

    /** PUBLIC VARS */
    // interface of the staking contract (stateful)
    iRadarStake public radarStakeContract;

    /** PUBLIC */
    // return totalStaked value unless user has triggered cooldown and that cooldown has expired, then return 0
    function balanceOf(address addr) external view returns (uint256) {
        // users current stake
        iRadarStake.Stake memory myStake = radarStakeContract.getStake(addr);
        // calculate the timestamp when the cooldown is over
        uint256 endOfCooldownTimestamp = myStake.cooldownTriggeredAtTimestamp + myStake.cooldownSeconds;

        // if cooldown has passed, return 0 staked tokens
        if (myStake.cooldownTriggeredAtTimestamp > 0 && block.timestamp >= endOfCooldownTimestamp) {
            return 0;
        }

        return myStake.totalStaked;
    }
    
    /** ONLY OWNER */
    function setContracts(address radarStakeContractAddr) external onlyOwner {
        require(address(radarStakeContractAddr) != address(0), "RadarStakingLogic: Staking contract not set");
        radarStakeContract = iRadarStake(radarStakeContractAddr);
    }
}