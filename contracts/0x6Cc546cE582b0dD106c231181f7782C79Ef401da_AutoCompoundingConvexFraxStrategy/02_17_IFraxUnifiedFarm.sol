// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

// solhint-disable var-name-mixedcase
// solhint-disable func-name-mixedcase

interface IFraxUnifiedFarm {
  // Struct for the stake
  struct LockedStake {
    bytes32 kek_id;
    uint256 start_timestamp;
    uint256 liquidity;
    uint256 ending_timestamp;
    uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
  }

  function lock_time_min() external view returns (uint256);

  function lock_time_for_max_multiplier() external view returns (uint256);

  // Total locked liquidity / LP tokens
  function lockedLiquidityOf(address account) external view returns (uint256);

  // Total 'balance' used for calculating the percent of the pool the account owns
  // Takes into account the locked stake time multiplier and veFXS multiplier
  function combinedWeightOf(address account) external view returns (uint256);

  // Calculate the combined weight for an account
  function calcCurCombinedWeight(address account)
    external
    view
    returns (
      uint256 old_combined_weight,
      uint256 new_vefxs_multiplier,
      uint256 new_combined_weight
    );

  function veFXSMultiplier(address account) external view returns (uint256 vefxs_multiplier);

  // All the locked stakes for a given account
  function lockedStakesOf(address account) external view returns (LockedStake[] memory);

  function calcCurrLockMultiplier(address account, uint256 stake_idx)
    external
    view
    returns (uint256 midpoint_lock_multiplier);
}