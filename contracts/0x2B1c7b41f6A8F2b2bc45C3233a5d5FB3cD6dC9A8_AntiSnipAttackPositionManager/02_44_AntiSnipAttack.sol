// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';

import {MathConstants as C} from '../../libraries/MathConstants.sol';
import {SafeCast} from '../../libraries/SafeCast.sol';

/// @title AntiSnipAttack
/// @notice Contains the snipping attack mechanism implementation
/// to be inherited by NFT position manager
library AntiSnipAttack {
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeCast for int128;

  struct Data {
    // timestamp of last action performed
    uint32 lastActionTime;
    // average start time of lock schedule
    uint32 lockTime;
    // average unlock time of locked fees
    uint32 unlockTime;
    // locked rToken qty since last update
    uint256 feesLocked;
  }

  /// @notice Initializes values for a new position
  /// @return data Initialized snip attack data structure
  function initialize(uint32 currentTime) internal pure returns (Data memory data) {
    data.lastActionTime = currentTime;
    data.lockTime = currentTime;
    data.unlockTime = currentTime;
    data.feesLocked = 0;
  }

  /// @notice Credits accumulated fees to a user's existing position
  /// @dev The posiition should already have been initialized
  /// @param self The individual position to update
  /// @param liquidityDelta The change in pool liquidity as a result of the position update
  /// this value should not be zero when called
  /// @param isAddLiquidity true = add liquidity, false = remove liquidity
  /// @param feesSinceLastAction rTokens collected by position since last action performed
  /// in fee growth inside the tick range
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  /// @return feesClaimable The claimable rToken amount to be sent to the user
  /// @return feesBurnable The rToken amount to be burnt
  function update(
    Data storage self,
    uint128 currentLiquidity,
    uint128 liquidityDelta,
    uint32 currentTime,
    bool isAddLiquidity,
    uint256 feesSinceLastAction,
    uint256 vestingPeriod
  ) internal returns (uint256 feesClaimable, uint256 feesBurnable) {
    Data memory _self = self;
    if (vestingPeriod == 0) {
      // no locked fees, return
      if (_self.feesLocked == 0) return (feesSinceLastAction, 0);
      // unlock any locked fees
      self.feesLocked = 0;
      return (_self.feesLocked + feesSinceLastAction, 0);
    }

    // scoping of fee proportions to avoid stack too deep
    {
      // claimable proportion (in basis pts) of collected fees between last action and now
      // lockTime is used instead of lastActionTime because we prefer to use the entire
      // duration of the position as the measure, not just the duration after last action performed
      uint256 feesClaimableSinceLastActionFeeUnits = Math.min(
        C.FEE_UNITS,
        (uint256(currentTime - _self.lockTime) * C.FEE_UNITS) / vestingPeriod
      );
      // claimable proportion (in basis pts) of locked fees
      // lastActionTime is used instead of lockTime since the vested fees
      // from lockTime to lastActionTime have already been claimed
      uint256 feesClaimableVestedFeeUnits = _self.unlockTime <= _self.lastActionTime
        ? C.FEE_UNITS
        : Math.min(
          C.FEE_UNITS,
          (uint256(currentTime - _self.lastActionTime) * C.FEE_UNITS) /
            (_self.unlockTime - _self.lastActionTime)
        );

      uint256 feesLockedBeforeUpdate = _self.feesLocked;
      (_self.feesLocked, feesClaimable) = calcFeeProportions(
        _self.feesLocked,
        feesSinceLastAction,
        feesClaimableVestedFeeUnits,
        feesClaimableSinceLastActionFeeUnits
      );

      // update unlock time
      // the new lock fee qty contains 2 portions:
      // (1) new lock fee qty from last action to now
      // (2) remaining lock fee qty prior to last action performed
      // new unlock time = proportionally weighted unlock times of the 2 portions
      // (1)'s unlock time = currentTime + vestingPeriod
      // (2)'s unlock time = current unlock time
      // If (1) and (2) are 0, then update to block.timestamp
      self.unlockTime = (_self.feesLocked == 0)
        ? currentTime
        : (((_self.lockTime + vestingPeriod) *
          feesSinceLastAction *
          (C.FEE_UNITS - feesClaimableSinceLastActionFeeUnits) +
          _self.unlockTime *
          feesLockedBeforeUpdate *
          (C.FEE_UNITS - feesClaimableVestedFeeUnits)) / (_self.feesLocked * C.FEE_UNITS))
        .toUint32();
    }

    uint256 updatedLiquidity = isAddLiquidity
      ? currentLiquidity + liquidityDelta
      : currentLiquidity - liquidityDelta;

    // adding liquidity: update average start time
    // removing liquidity: calculate and burn portion of locked fees
    if (isAddLiquidity) {
      self.lockTime = Math
      .ceilDiv(
        Math.max(_self.lockTime, currentTime - vestingPeriod) *
          uint256(currentLiquidity) +
          uint256(uint128(liquidityDelta)) *
          currentTime,
        updatedLiquidity
      ).toUint32();
    } else if (_self.feesLocked > 0) {
      feesBurnable = (_self.feesLocked * liquidityDelta) / uint256(currentLiquidity);
      _self.feesLocked -= feesBurnable;
    }

    // update other variables
    self.feesLocked = _self.feesLocked;
    self.lastActionTime = currentTime;
  }

  function calcFeeProportions(
    uint256 currentFees,
    uint256 nextFees,
    uint256 currentClaimableFeeUnits,
    uint256 nextClaimableFeeUnits
  ) internal pure returns (uint256 feesLockedNew, uint256 feesClaimable) {
    uint256 totalFees = currentFees + nextFees;
    feesClaimable =
      (currentClaimableFeeUnits * currentFees + nextClaimableFeeUnits * nextFees) /
      C.FEE_UNITS;
    feesLockedNew = totalFees - feesClaimable;
  }
}