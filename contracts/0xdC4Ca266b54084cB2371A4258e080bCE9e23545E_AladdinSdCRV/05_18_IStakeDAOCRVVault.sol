// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IStakeDAOMultiMerkleStash.sol";
import "./IStakeDAOVault.sol";

interface IStakeDAOCRVVault is IStakeDAOVault {
  /// @notice Emitted when the withdraw lock time is updated.
  /// @param _withdrawLockTime The new withdraw lock time in seconds.
  event UpdateWithdrawLockTime(uint256 _withdrawLockTime);

  /// @notice Emitted when someone harvest pending sdCRV bribe rewards.
  /// @param _token The address of the reward token.
  /// @param _reward The amount of harvested rewards.
  /// @param _platformFee The amount of platform fee taken.
  /// @param _boostFee The amount SDT for veSDT boost delegation fee.
  event HarvestBribe(address _token, uint256 _reward, uint256 _platformFee, uint256 _boostFee);

  /// @notice Deposit some CRV to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  /// @param _minOut The minimum amount of sdCRV should received.
  /// @return _amountOut The amount of sdCRV received.
  function depositWithCRV(
    uint256 _amount,
    address _recipient,
    uint256 _minOut
  ) external returns (uint256 _amountOut);

  /// @notice Deposit some CRV to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function depositWithSdVeCRV(uint256 _amount, address _recipient) external;

  /// @notice Harvest sdCRV bribes.
  /// @dev No harvest bounty when others call this function.
  /// @param _claims The claim parameters passing to StakeDAOMultiMerkleStash contract.
  function harvestBribes(IStakeDAOMultiMerkleStash.claimParam[] memory _claims) external;
}