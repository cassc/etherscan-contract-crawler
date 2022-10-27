// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title Alloyx Stake Info Interface
 * @author AlloyX
 */
interface IAlloyxStakeInfo {
  /**
   * @notice Add stake for a staker
   * @param _staker The person intending to stake
   * @param _stake The size of the stake to be created.
   */
  function addStake(address _staker, uint256 _stake) external;

  /**
   * @notice Remove stake for a staker
   * @param _staker The person intending to remove stake
   * @param _stake The size of the stake to be removed.
   */
  function removeStake(address _staker, uint256 _stake) external;

  /**
   * @notice A method for a stakeholder to clear a stake with some leftover reward
   * @param _staker the address of the staker
   * @param _reward the leftover reward the staker owns
   */
  function resetStakeTimestampWithRewardLeft(address _staker, uint256 _reward) external;

  /**
   * @notice Claimable CRWN token amount of an address
   * @param _receiver the address of receiver
   */
  function claimableCRWNToken(address _receiver) external view returns (uint256);

  /**
   * @notice Total claimable CRWN tokens of all stakeholders
   */
  function totalClaimableCRWNToken() external view returns (uint256);
}