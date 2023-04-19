// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title IStakeDesk
 * @author AlloyX
 */
interface IStakeDesk {
  /**
   * @notice Set map from vault address to gov token address
   * @param _vaultAddress the address of the vault
   * @param _govTokenAddress the address of the governance token
   */
  function setGovTokenForVault(address _vaultAddress, address _govTokenAddress) external;

  /**
   * @notice Stake more ALYX into the vault, which will cause to mint govToken for the staker
   * @param _account the account to add stake
   * @param _amount the amount the message sender intending to stake in
   */
  function addPermanentStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Unstake some from the vault, which will cause the vault to burn govToken for the staker
   * @param _account the account to reduce stake
   * @param _amount the amount the message sender intending to unstake
   */
  function subPermanentStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Stake more into the vault,which will cause to mint govToken for the staker
   * @param _account the account to add stake
   * @param _amount the amount the message sender intending to stake in
   */
  function addRegularStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Unstake some from the vault, which will cause the vault to burn govToken for the staker
   * @param _account the account to reduce stake
   * @param _amount the amount the message sender intending to unstake
   */
  function subRegularStakeInfo(address _account, uint256 _amount) external;

  /**
   * @notice Unstake all the regular and permanent stakers and burn all govTokens
   */
  function unstakeAllStakersAndBurnAllGovTokens() external;

  /**
   * @notice Get the prorated gain for regular staker
   * @param _staker the staker to calculate the gain to whom the gain is entitled
   * @param _gain the total gain for all regular stakers
   */
  function getRegularStakerProrataGain(address _staker, uint256 _gain) external view returns (uint256);

  /**
   * @notice Get the prorated gain for permanent staker
   * @param _staker the staker to calculate the gain to whom the gain is entitled
   * @param _gain the total gain for all permanent stakers
   */
  function getPermanentStakerProrataGain(address _staker, uint256 _gain) external view returns (uint256);

  /**
   * @notice Clear all stake info for staker
   * @param _staker the staker to clear the stake info for
   */
  function clearStakeInfoAfterClaiming(address _staker) external;
}