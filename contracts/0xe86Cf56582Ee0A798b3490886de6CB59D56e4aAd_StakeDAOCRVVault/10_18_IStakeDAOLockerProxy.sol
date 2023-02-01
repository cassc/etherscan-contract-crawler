// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStakeDAOMultiMerkleStash.sol";

interface IStakeDAOLockerProxy {
  /// @notice Deposit staked token to StakeDAO gauge.
  /// @dev The caller should make sure the token is already transfered to the contract.
  /// @param _gauge The address of gauge.
  /// @param _token The address token to deposit.
  /// @return _amount The amount of token deposited. This can be used for cross validation.
  function deposit(address _gauge, address _token) external returns (uint256 _amount);

  /// @notice Withdraw staked token from StakeDAO gauge.
  /// @param _gauge The address of gauge.
  /// @param _token The address token to withdraw.
  /// @param _amount The amount of token to withdraw.
  /// @param _recipient The address of recipient who will receive the staked token.
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount,
    address _recipient
  ) external;

  /// @notice Claim pending rewards from StakeDAO gauge.
  /// @dev Be careful that the StakeDAO gauge supports `claim_rewards_for`. Currently,
  /// it is fine since only owner can call the function through `ClaimRewards` contract.
  /// @param _gauge The address of gauge to claim.
  /// @param _tokens The list of reward tokens to claim.
  /// @return _amounts The list of amount of rewards claim for corresponding tokens.
  function claimRewards(address _gauge, address[] calldata _tokens) external returns (uint256[] memory _amounts);

  /// @notice Claim bribe rewards for sdCRV.
  /// @param _claims The claim parameters passing to StakeDAOMultiMerkleStash contract.
  /// @param _recipient The address of recipient who will receive the bribe rewards.
  function claimBribeRewards(IStakeDAOMultiMerkleStash.claimParam[] memory _claims, address _recipient) external;
}