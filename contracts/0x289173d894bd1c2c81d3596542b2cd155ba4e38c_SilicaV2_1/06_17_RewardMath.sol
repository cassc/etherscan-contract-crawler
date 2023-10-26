/**
     _    _ _    _           _             
    / \  | | | _(_)_ __ ___ (_)_   _  __ _ 
   / _ \ | | |/ / | '_ ` _ \| | | | |/ _` |
  / ___ \| |   <| | | | | | | | |_| | (_| |
 /_/   \_\_|_|\_\_|_| |_| |_|_|\__, |\__,_|
                               |___/        
**/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title  Reward Math Library
 * @author Alkimiya Team
 * @notice Calculations for when buyer initiates default
 */
library RewardMath {

    /// @notice Function to calculate the mining reward due by the seller
    /// @param _hashrate Underlying hashrate amount
    /// @param _networkReward Snapshot of the total network reward (block subsidy + fees)
    /// @param _networkHashrate The hashrate of the network (The basic unit of measurement of hashpower. Measures the number of SHA256d computations performed per second)
    function _getMiningRewardDue(
        uint256 _hashrate,
        uint256 _networkReward,
        uint256 _networkHashrate
    ) internal pure returns (uint256) {
        return (_hashrate * _networkReward) / _networkHashrate;
    }

    /// @notice Function to calculate the reward due by the seller for Eth Staking Silica
    /// @param _stakedAmount The amount that has been staked
    /// @param _baseRewardPerIncrementPerDay The amount paid to the blockspace producer from the protocol, through inflation.
    /// @param @decimals The amount of decimals of the Silica 
    /// @return uint256: The amount of reward tokens due
    function _getEthStakingRewardDue(
        uint256 _stakedAmount,
        uint256 _baseRewardPerIncrementPerDay,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (_stakedAmount * _baseRewardPerIncrementPerDay) / (10**decimals);
    }
}