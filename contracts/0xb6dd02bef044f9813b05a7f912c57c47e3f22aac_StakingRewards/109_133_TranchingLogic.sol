// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IV2CreditLine} from "../../interfaces/IV2CreditLine.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {FixedPoint} from "../../external/FixedPoint.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title TranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library TranchingLogic {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;
  using ConfigHelper for GoldfinchConfig;

  struct SliceInfo {
    uint256 reserveFeePercent;
    uint256 interestAccrued;
    uint256 principalAccrued;
  }

  struct ApplyResult {
    uint256 interestRemaining;
    uint256 principalRemaining;
    uint256 reserveDeduction;
    uint256 oldInterestSharePrice;
    uint256 oldPrincipalSharePrice;
  }

  uint256 internal constant FP_SCALING_FACTOR = 1e18;
  uint256 public constant NUM_TRANCHES_PER_SLICE = 2;

  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return totalShares == 0 ? 0 : amount.mul(FP_SCALING_FACTOR).div(totalShares);
  }

  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return sharePrice.mul(totalShares).div(FP_SCALING_FACTOR);
  }

  function lockTranche(ITranchedPool.TrancheInfo storage tranche, GoldfinchConfig config) external {
    tranche.lockedUntil = block.timestamp.add(config.getDrawdownPeriodInSeconds());
    emit TrancheLocked(address(this), tranche.id, tranche.lockedUntil);
  }

  function redeemableInterestAndPrincipal(
    ITranchedPool.TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo
  ) public view returns (uint256, uint256) {
    // This supports withdrawing before or after locking because principal share price starts at 1
    // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
    uint256 maxPrincipalRedeemable = sharePriceToUsdc(
      trancheInfo.principalSharePrice,
      tokenInfo.principalAmount
    );
    // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
    // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
    uint256 maxInterestRedeemable = sharePriceToUsdc(
      trancheInfo.interestSharePrice,
      tokenInfo.principalAmount
    );

    uint256 interestRedeemable = maxInterestRedeemable.sub(tokenInfo.interestRedeemed);
    uint256 principalRedeemable = maxPrincipalRedeemable.sub(tokenInfo.principalRedeemed);

    return (interestRedeemable, principalRedeemable);
  }

  function calculateExpectedSharePrice(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) public pure returns (uint256) {
    uint256 sharePrice = usdcToSharePrice(amount, tranche.principalDeposited);
    return _scaleByPercentOwnership(tranche, sharePrice, slice);
  }

  function scaleForSlice(
    ITranchedPool.PoolSlice memory slice,
    uint256 amount,
    uint256 totalDeployed
  ) public pure returns (uint256) {
    return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
  }

  // We need to create this struct so we don't run into a stack too deep error due to too many variables
  function getSliceInfo(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed,
    uint256 reserveFeePercent
  ) public view returns (SliceInfo memory) {
    (uint256 interestAccrued, uint256 principalAccrued) = getTotalInterestAndPrincipal(
      slice,
      creditLine,
      totalDeployed
    );
    return
      SliceInfo({
        reserveFeePercent: reserveFeePercent,
        interestAccrued: interestAccrued,
        principalAccrued: principalAccrued
      });
  }

  function getTotalInterestAndPrincipal(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed
  ) public view returns (uint256, uint256) {
    uint256 principalAccrued = creditLine.principalOwed();
    // In addition to principal actually owed, we need to account for early principal payments
    // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
    // 5K (balance- deployed) + 0 (principal owed)
    principalAccrued = totalDeployed.sub(creditLine.balance()).add(principalAccrued);
    // Now we need to scale that correctly for the slice we're interested in
    principalAccrued = scaleForSlice(slice, principalAccrued, totalDeployed);
    // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
    // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
    // share price starts at 1, and is decremented by what was drawn down.
    uint256 totalDeposited = slice.seniorTranche.principalDeposited.add(
      slice.juniorTranche.principalDeposited
    );
    principalAccrued = totalDeposited.sub(slice.principalDeployed).add(principalAccrued);
    return (slice.totalInterestAccrued, principalAccrued);
  }

  function scaleByFraction(
    uint256 amount,
    uint256 fraction,
    uint256 total
  ) public pure returns (uint256) {
    FixedPoint.Unsigned memory totalAsFixedPoint = FixedPoint.fromUnscaledUint(total);
    FixedPoint.Unsigned memory fractionAsFixedPoint = FixedPoint.fromUnscaledUint(fraction);
    return fractionAsFixedPoint.div(totalAsFixedPoint).mul(amount).div(FP_SCALING_FACTOR).rawValue;
  }

  /// @notice apply a payment to all slices
  /// @param poolSlices slices to apply to
  /// @param numSlices number of slices
  /// @param interest amount of interest to apply
  /// @param principal amount of principal to apply
  /// @param reserveFeePercent percentage that protocol will take for reserves
  /// @param totalDeployed total amount of principal deployed
  /// @param creditLine creditline to account for
  /// @param juniorFeePercent percentage the junior tranche will take
  /// @return total amount that will be sent to reserves
  function applyToAllSlices(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 numSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine,
    uint256 juniorFeePercent
  ) external returns (uint256) {
    ApplyResult memory result = TranchingLogic.applyToAllSeniorTranches(
      poolSlices,
      numSlices,
      interest,
      principal,
      reserveFeePercent,
      totalDeployed,
      creditLine,
      juniorFeePercent
    );

    return
      result.reserveDeduction.add(
        TranchingLogic.applyToAllJuniorTranches(
          poolSlices,
          numSlices,
          result.interestRemaining,
          result.principalRemaining,
          reserveFeePercent,
          totalDeployed,
          creditLine
        )
      );
  }

  function applyToAllSeniorTranches(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 numSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine,
    uint256 juniorFeePercent
  ) internal returns (ApplyResult memory) {
    ApplyResult memory seniorApplyResult;
    for (uint256 i = 0; i < numSlices; i++) {
      ITranchedPool.PoolSlice storage slice = poolSlices[i];

      SliceInfo memory sliceInfo = getSliceInfo(
        slice,
        creditLine,
        totalDeployed,
        reserveFeePercent
      );

      // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
      // pro-rata across the slices. So we scale the interest and principal to the slice
      ApplyResult memory applyResult = applyToSeniorTranche(
        slice,
        scaleForSlice(slice, interest, totalDeployed),
        scaleForSlice(slice, principal, totalDeployed),
        juniorFeePercent,
        sliceInfo
      );
      emitSharePriceUpdatedEvent(slice.seniorTranche, applyResult);
      seniorApplyResult.interestRemaining = seniorApplyResult.interestRemaining.add(
        applyResult.interestRemaining
      );
      seniorApplyResult.principalRemaining = seniorApplyResult.principalRemaining.add(
        applyResult.principalRemaining
      );
      seniorApplyResult.reserveDeduction = seniorApplyResult.reserveDeduction.add(
        applyResult.reserveDeduction
      );
    }
    return seniorApplyResult;
  }

  function applyToAllJuniorTranches(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 numSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine
  ) internal returns (uint256 totalReserveAmount) {
    for (uint256 i = 0; i < numSlices; i++) {
      SliceInfo memory sliceInfo = getSliceInfo(
        poolSlices[i],
        creditLine,
        totalDeployed,
        reserveFeePercent
      );
      // Any remaining interest and principal is then shared pro-rata with the junior slices
      ApplyResult memory applyResult = applyToJuniorTranche(
        poolSlices[i],
        scaleForSlice(poolSlices[i], interest, totalDeployed),
        scaleForSlice(poolSlices[i], principal, totalDeployed),
        sliceInfo
      );
      emitSharePriceUpdatedEvent(poolSlices[i].juniorTranche, applyResult);
      totalReserveAmount = totalReserveAmount.add(applyResult.reserveDeduction);
    }
    return totalReserveAmount;
  }

  function emitSharePriceUpdatedEvent(
    ITranchedPool.TrancheInfo memory tranche,
    ApplyResult memory applyResult
  ) internal {
    emit SharePriceUpdated(
      address(this),
      tranche.id,
      tranche.principalSharePrice,
      int256(tranche.principalSharePrice.sub(applyResult.oldPrincipalSharePrice)),
      tranche.interestSharePrice,
      int256(tranche.interestSharePrice.sub(applyResult.oldInterestSharePrice))
    );
  }

  function applyToSeniorTranche(
    ITranchedPool.PoolSlice storage slice,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 juniorFeePercent,
    SliceInfo memory sliceInfo
  ) internal returns (ApplyResult memory) {
    // First determine the expected share price for the senior tranche. This is the gross amount the senior
    // tranche should receive.
    uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
      slice.seniorTranche,
      sliceInfo.interestAccrued,
      slice
    );
    uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
      slice.seniorTranche,
      sliceInfo.principalAccrued,
      slice
    );

    // Deduct the junior fee and the protocol reserve
    uint256 desiredNetInterestSharePrice = scaleByFraction(
      expectedInterestSharePrice,
      uint256(100).sub(juniorFeePercent.add(sliceInfo.reserveFeePercent)),
      uint256(100)
    );
    // Collect protocol fee interest received (we've subtracted this from the senior portion above)
    uint256 reserveDeduction = scaleByFraction(
      interestRemaining,
      sliceInfo.reserveFeePercent,
      uint256(100)
    );
    interestRemaining = interestRemaining.sub(reserveDeduction);
    uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.seniorTranche.principalSharePrice;
    // Apply the interest remaining so we get up to the netInterestSharePrice
    (interestRemaining, principalRemaining) = _applyBySharePrice(
      slice.seniorTranche,
      interestRemaining,
      principalRemaining,
      desiredNetInterestSharePrice,
      expectedPrincipalSharePrice
    );
    return
      ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function applyToJuniorTranche(
    ITranchedPool.PoolSlice storage slice,
    uint256 interestRemaining,
    uint256 principalRemaining,
    SliceInfo memory sliceInfo
  ) public returns (ApplyResult memory) {
    // Then fill up the junior tranche with all the interest remaining, upto the principal share price
    uint256 expectedInterestSharePrice = slice.juniorTranche.interestSharePrice.add(
      usdcToSharePrice(interestRemaining, slice.juniorTranche.principalDeposited)
    );
    uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
      slice.juniorTranche,
      sliceInfo.principalAccrued,
      slice
    );
    uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.juniorTranche.principalSharePrice;
    (interestRemaining, principalRemaining) = _applyBySharePrice(
      slice.juniorTranche,
      interestRemaining,
      principalRemaining,
      expectedInterestSharePrice,
      expectedPrincipalSharePrice
    );

    // All remaining interest and principal is applied towards the junior tranche as interest
    interestRemaining = interestRemaining.add(principalRemaining);
    // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
    // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
    // fee on the original interest portion)
    uint256 reserveDeduction = scaleByFraction(
      principalRemaining,
      sliceInfo.reserveFeePercent,
      uint256(100)
    );
    interestRemaining = interestRemaining.sub(reserveDeduction);
    principalRemaining = 0;

    (interestRemaining, principalRemaining) = _applyByAmount(
      slice.juniorTranche,
      interestRemaining.add(principalRemaining),
      0,
      interestRemaining.add(principalRemaining),
      0
    );
    return
      ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function migrateAccountingVariables(IV2CreditLine originalCl, IV2CreditLine newCl) external {
    // Copy over all accounting variables
    newCl.setBalance(originalCl.balance());
    newCl.setLimit(originalCl.limit());
    newCl.setInterestOwed(originalCl.interestOwed());
    newCl.setPrincipalOwed(originalCl.principalOwed());
    newCl.setTermEndTime(originalCl.termEndTime());
    newCl.setNextDueTime(originalCl.nextDueTime());
    newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
    newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
    newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
  }

  function closeCreditLine(IV2CreditLine cl) external {
    // Close out old CL
    cl.setBalance(0);
    cl.setLimit(0);
    cl.setMaxLimit(0);
  }

  function trancheIdToSliceIndex(uint256 trancheId) external pure returns (uint256) {
    return trancheId.sub(1).div(NUM_TRANCHES_PER_SLICE);
  }

  function initializeNextSlice(
    mapping(uint256 => ITranchedPool.PoolSlice) storage poolSlices,
    uint256 sliceIndex
  ) external {
    poolSlices[sliceIndex] = ITranchedPool.PoolSlice({
      seniorTranche: ITranchedPool.TrancheInfo({
        id: sliceIndexToSeniorTrancheId(sliceIndex),
        principalSharePrice: usdcToSharePrice(1, 1),
        interestSharePrice: 0,
        principalDeposited: 0,
        lockedUntil: 0
      }),
      juniorTranche: ITranchedPool.TrancheInfo({
        id: sliceIndexToJuniorTrancheId(sliceIndex),
        principalSharePrice: usdcToSharePrice(1, 1),
        interestSharePrice: 0,
        principalDeposited: 0,
        lockedUntil: 0
      }),
      totalInterestAccrued: 0,
      principalDeployed: 0
    });
  }

  function sliceIndexToJuniorTrancheId(uint256 sliceIndex) public pure returns (uint256) {
    // 0 -> 2
    // 1 -> 4
    return sliceIndex.mul(NUM_TRANCHES_PER_SLICE).add(2);
  }

  function sliceIndexToSeniorTrancheId(uint256 sliceIndex) public pure returns (uint256) {
    // 0 -> 1
    // 1 -> 3
    return sliceIndex.mul(NUM_TRANCHES_PER_SLICE).add(1);
  }

  function isSeniorTrancheId(uint256 trancheId) external pure returns (bool) {
    return trancheId.mod(TranchingLogic.NUM_TRANCHES_PER_SLICE) == 1;
  }

  function isJuniorTrancheId(uint256 trancheId) external pure returns (bool) {
    return trancheId != 0 && trancheId.mod(TranchingLogic.NUM_TRANCHES_PER_SLICE) == 0;
  }

  // // INTERNAL //////////////////////////////////////////////////////////////////

  function _applyToSharePrice(
    uint256 amountRemaining,
    uint256 currentSharePrice,
    uint256 desiredAmount,
    uint256 totalShares
  ) internal pure returns (uint256, uint256) {
    // If no money left to apply, or don't need any changes, return the original amounts
    if (amountRemaining == 0 || desiredAmount == 0) {
      return (amountRemaining, currentSharePrice);
    }
    if (amountRemaining < desiredAmount) {
      // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
      desiredAmount = amountRemaining;
    }
    uint256 sharePriceDifference = usdcToSharePrice(desiredAmount, totalShares);
    return (amountRemaining.sub(desiredAmount), currentSharePrice.add(sharePriceDifference));
  }

  function _scaleByPercentOwnership(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) internal pure returns (uint256) {
    uint256 totalDeposited = slice.juniorTranche.principalDeposited.add(
      slice.seniorTranche.principalDeposited
    );
    return scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
  }

  function _desiredAmountFromSharePrice(
    uint256 desiredSharePrice,
    uint256 actualSharePrice,
    uint256 totalShares
  ) internal pure returns (uint256) {
    // If the desired share price is lower, then ignore it, and leave it unchanged
    if (desiredSharePrice < actualSharePrice) {
      desiredSharePrice = actualSharePrice;
    }
    uint256 sharePriceDifference = desiredSharePrice.sub(actualSharePrice);
    return sharePriceToUsdc(sharePriceDifference, totalShares);
  }

  function _applyByAmount(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestAmount,
    uint256 desiredPrincipalAmount
  ) internal returns (uint256, uint256) {
    uint256 totalShares = tranche.principalDeposited;
    uint256 newSharePrice;

    (interestRemaining, newSharePrice) = _applyToSharePrice(
      interestRemaining,
      tranche.interestSharePrice,
      desiredInterestAmount,
      totalShares
    );
    tranche.interestSharePrice = newSharePrice;

    (principalRemaining, newSharePrice) = _applyToSharePrice(
      principalRemaining,
      tranche.principalSharePrice,
      desiredPrincipalAmount,
      totalShares
    );
    tranche.principalSharePrice = newSharePrice;
    return (interestRemaining, principalRemaining);
  }

  function _applyBySharePrice(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestSharePrice,
    uint256 desiredPrincipalSharePrice
  ) internal returns (uint256, uint256) {
    uint256 desiredInterestAmount = _desiredAmountFromSharePrice(
      desiredInterestSharePrice,
      tranche.interestSharePrice,
      tranche.principalDeposited
    );
    uint256 desiredPrincipalAmount = _desiredAmountFromSharePrice(
      desiredPrincipalSharePrice,
      tranche.principalSharePrice,
      tranche.principalDeposited
    );
    return
      _applyByAmount(
        tranche,
        interestRemaining,
        principalRemaining,
        desiredInterestAmount,
        desiredPrincipalAmount
      );
  }

  // // Events /////////////////////////////////////////////////////////////////////

  // NOTE: this needs to match the event in TranchedPool
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);

  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
}