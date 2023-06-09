// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IAlloyxStakeInfo
 * @author AlloyX
 */
interface IAlloyxStakeInfo {
  function getAllStakers(address _vaultAddress) external returns (address[] memory);

  /**
   * @notice Add stake for a staker
   * @param _vaultAddress The vault address
   * @param _staker The person intending to stake
   * @param _stake The size of the stake to be created.
   */
  function addStake(
    address _vaultAddress,
    address _staker,
    uint256 _stake
  ) external;

  /**
   * @notice Remove stake for a staker
   * @param _vaultAddress The vault address
   * @param _staker The person intending to remove stake
   * @param _stake The size of the stake to be removed.
   */
  function removeStake(
    address _vaultAddress,
    address _staker,
    uint256 _stake
  ) external;

  /**
   * @notice Remove all stakes with regards to one vault
   * @param _vaultAddress The vault address
   */
  function removeAllStake(address _vaultAddress) external;

  /**
   * @notice Total receiver temporal stakes
   * @param _vaultAddress The vault address
   * @param _receiver the address of receiver
   */
  function receiverTemporalStake(address _vaultAddress, address _receiver) external view returns (uint256);

  /**
   * @notice Total vault temporal stakes
   * @param _vaultAddress The vault address
   */
  function vaultTemporalStake(address _vaultAddress) external view returns (uint256);

  /**
   * @notice A method for a stakeholder to clear a stake with some leftover temporal stakes
   * @param _vaultAddress The vault address
   * @param _staker the address of the staker
   * @param _temporalStake the leftover temporal stake
   */
  function resetStakeTimestampWithTemporalStake(
    address _vaultAddress,
    address _staker,
    uint256 _temporalStake
  ) external;

  /**
   * @notice Retrieve the stake for a stakeholder.
   * @param _staker The staker
   * @return stakes The amount staked and the time since when it's staked.
   */
  function totalStakeForUser(address _staker) external view returns (uint256);
}