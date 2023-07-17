// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Calculations for when buyer initiates default
 * @author Alkimiya Team
 */
library RewardMath {
    function getMiningRewardDue(
        uint256 _hashrate,
        uint256 _networkReward,
        uint256 _networkHashrate
    ) internal pure returns (uint256) {
        return (_hashrate * _networkReward) / _networkHashrate;
    }

    function getEthStakingRewardDue(
        uint256 _stakedAmount,
        uint256 _baseRewardPerIncrementPerDay,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (_stakedAmount * _baseRewardPerIncrementPerDay) / (10**decimals);
    }
}