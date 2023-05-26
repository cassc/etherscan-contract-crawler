// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../interfaces/IV2CreditLine.sol";
import "../../interfaces/ITranchedPool.sol";
import "../../interfaces/IPoolTokens.sol";
import "../../external/FixedPoint.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

/**
 * @title TranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library TranchingLogic {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;

  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );

  uint256 public constant FP_SCALING_FACTOR = 1e18;
  uint256 public constant ONE_HUNDRED = 100; // Need this because we cannot call .div on a literal 100

  function usdcToSharePrice(uint256 amount, uint256 totalShares) public pure returns (uint256) {
    return totalShares == 0 ? 0 : amount.mul(FP_SCALING_FACTOR).div(totalShares);
  }

  function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares) public pure returns (uint256) {
    return sharePrice.mul(totalShares).div(FP_SCALING_FACTOR);
  }

  function redeemableInterestAndPrincipal(
    ITranchedPool.TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo
  ) public view returns (uint256 interestRedeemable, uint256 principalRedeemable) {
    // This supports withdrawing before or after locking because principal share price starts at 1
    // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
    uint256 maxPrincipalRedeemable = sharePriceToUsdc(trancheInfo.principalSharePrice, tokenInfo.principalAmount);
    // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
    // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
    uint256 maxInterestRedeemable = sharePriceToUsdc(trancheInfo.interestSharePrice, tokenInfo.principalAmount);

    interestRedeemable = maxInterestRedeemable.sub(tokenInfo.interestRedeemed);
    principalRedeemable = maxPrincipalRedeemable.sub(tokenInfo.principalRedeemed);

    return (interestRedeemable, principalRedeemable);
  }

  function calculateExpectedSharePrice(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) public pure returns (uint256) {
    uint256 sharePrice = usdcToSharePrice(amount, tranche.principalDeposited);
    return scaleByPercentOwnership(tranche, sharePrice, slice);
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
  ) public view returns (ITranchedPool.SliceInfo memory) {
    (uint256 interestAccrued, uint256 principalAccrued) = getTotalInterestAndPrincipal(
      slice,
      creditLine,
      totalDeployed
    );
    return
      ITranchedPool.SliceInfo({
        reserveFeePercent: reserveFeePercent,
        interestAccrued: interestAccrued,
        principalAccrued: principalAccrued
      });
  }

  function getTotalInterestAndPrincipal(
    ITranchedPool.PoolSlice memory slice,
    IV2CreditLine creditLine,
    uint256 totalDeployed
  ) public view returns (uint256 interestAccrued, uint256 principalAccrued) {
    principalAccrued = creditLine.principalOwed();
    // In addition to principal actually owed, we need to account for early principal payments
    // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
    // 5K (balance- deployed) + 0 (principal owed)
    principalAccrued = totalDeployed.sub(creditLine.balance()).add(principalAccrued);
    // Now we need to scale that correctly for the slice we're interested in
    principalAccrued = scaleForSlice(slice, principalAccrued, totalDeployed);
    // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
    // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
    // share price starts at 1, and is decremented by what was drawn down.
    uint256 totalDeposited = slice.seniorTranche.principalDeposited.add(slice.juniorTranche.principalDeposited);
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

  function applyToAllSeniorTranches(
    ITranchedPool.PoolSlice[] storage poolSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine,
    uint256 juniorFeePercent
  ) public returns (ITranchedPool.ApplyResult memory) {
    ITranchedPool.ApplyResult memory seniorApplyResult;
    for (uint256 i = 0; i < poolSlices.length; i++) {
      ITranchedPool.SliceInfo memory sliceInfo = getSliceInfo(
        poolSlices[i],
        creditLine,
        totalDeployed,
        reserveFeePercent
      );

      // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
      // pro-rata across the slices. So we scale the interest and principal to the slice
      ITranchedPool.ApplyResult memory applyResult = applyToSeniorTranche(
        poolSlices[i],
        scaleForSlice(poolSlices[i], interest, totalDeployed),
        scaleForSlice(poolSlices[i], principal, totalDeployed),
        juniorFeePercent,
        sliceInfo
      );
      emitSharePriceUpdatedEvent(poolSlices[i].seniorTranche, applyResult);
      seniorApplyResult.interestRemaining = seniorApplyResult.interestRemaining.add(applyResult.interestRemaining);
      seniorApplyResult.principalRemaining = seniorApplyResult.principalRemaining.add(applyResult.principalRemaining);
      seniorApplyResult.reserveDeduction = seniorApplyResult.reserveDeduction.add(applyResult.reserveDeduction);
    }
    return seniorApplyResult;
  }

  function applyToAllJuniorTranches(
    ITranchedPool.PoolSlice[] storage poolSlices,
    uint256 interest,
    uint256 principal,
    uint256 reserveFeePercent,
    uint256 totalDeployed,
    IV2CreditLine creditLine
  ) public returns (uint256 totalReserveAmount) {
    for (uint256 i = 0; i < poolSlices.length; i++) {
      ITranchedPool.SliceInfo memory sliceInfo = getSliceInfo(
        poolSlices[i],
        creditLine,
        totalDeployed,
        reserveFeePercent
      );
      // Any remaining interest and principal is then shared pro-rata with the junior slices
      ITranchedPool.ApplyResult memory applyResult = applyToJuniorTranche(
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
    ITranchedPool.ApplyResult memory applyResult
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
    ITranchedPool.SliceInfo memory sliceInfo
  ) public returns (ITranchedPool.ApplyResult memory) {
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
      ONE_HUNDRED.sub(juniorFeePercent.add(sliceInfo.reserveFeePercent)),
      ONE_HUNDRED
    );
    // Collect protocol fee interest received (we've subtracted this from the senior portion above)
    uint256 reserveDeduction = scaleByFraction(interestRemaining, sliceInfo.reserveFeePercent, ONE_HUNDRED);
    interestRemaining = interestRemaining.sub(reserveDeduction);
    uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
    uint256 oldPrincipalSharePrice = slice.seniorTranche.principalSharePrice;
    // Apply the interest remaining so we get up to the netInterestSharePrice
    (interestRemaining, principalRemaining) = applyBySharePrice(
      slice.seniorTranche,
      interestRemaining,
      principalRemaining,
      desiredNetInterestSharePrice,
      expectedPrincipalSharePrice
    );
    return
      ITranchedPool.ApplyResult({
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
    ITranchedPool.SliceInfo memory sliceInfo
  ) public returns (ITranchedPool.ApplyResult memory) {
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
    (interestRemaining, principalRemaining) = applyBySharePrice(
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
    uint256 reserveDeduction = scaleByFraction(principalRemaining, sliceInfo.reserveFeePercent, ONE_HUNDRED);
    interestRemaining = interestRemaining.sub(reserveDeduction);
    principalRemaining = 0;

    (interestRemaining, principalRemaining) = applyByAmount(
      slice.juniorTranche,
      interestRemaining.add(principalRemaining),
      0,
      interestRemaining.add(principalRemaining),
      0
    );
    return
      ITranchedPool.ApplyResult({
        interestRemaining: interestRemaining,
        principalRemaining: principalRemaining,
        reserveDeduction: reserveDeduction,
        oldInterestSharePrice: oldInterestSharePrice,
        oldPrincipalSharePrice: oldPrincipalSharePrice
      });
  }

  function applyBySharePrice(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestSharePrice,
    uint256 desiredPrincipalSharePrice
  ) public returns (uint256, uint256) {
    uint256 desiredInterestAmount = desiredAmountFromSharePrice(
      desiredInterestSharePrice,
      tranche.interestSharePrice,
      tranche.principalDeposited
    );
    uint256 desiredPrincipalAmount = desiredAmountFromSharePrice(
      desiredPrincipalSharePrice,
      tranche.principalSharePrice,
      tranche.principalDeposited
    );
    return applyByAmount(tranche, interestRemaining, principalRemaining, desiredInterestAmount, desiredPrincipalAmount);
  }

  function applyByAmount(
    ITranchedPool.TrancheInfo storage tranche,
    uint256 interestRemaining,
    uint256 principalRemaining,
    uint256 desiredInterestAmount,
    uint256 desiredPrincipalAmount
  ) public returns (uint256, uint256) {
    uint256 totalShares = tranche.principalDeposited;
    uint256 newSharePrice;

    (interestRemaining, newSharePrice) = applyToSharePrice(
      interestRemaining,
      tranche.interestSharePrice,
      desiredInterestAmount,
      totalShares
    );
    tranche.interestSharePrice = newSharePrice;

    (principalRemaining, newSharePrice) = applyToSharePrice(
      principalRemaining,
      tranche.principalSharePrice,
      desiredPrincipalAmount,
      totalShares
    );
    tranche.principalSharePrice = newSharePrice;
    return (interestRemaining, principalRemaining);
  }

  function migrateAccountingVariables(address originalClAddr, address newClAddr) public {
    IV2CreditLine originalCl = IV2CreditLine(originalClAddr);
    IV2CreditLine newCl = IV2CreditLine(newClAddr);

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

  function closeCreditLine(address originalCl) public {
    // Close out old CL
    IV2CreditLine oldCreditLine = IV2CreditLine(originalCl);
    oldCreditLine.setBalance(0);
    oldCreditLine.setLimit(0);
    oldCreditLine.setMaxLimit(0);
  }

  function desiredAmountFromSharePrice(
    uint256 desiredSharePrice,
    uint256 actualSharePrice,
    uint256 totalShares
  ) public pure returns (uint256) {
    // If the desired share price is lower, then ignore it, and leave it unchanged
    if (desiredSharePrice < actualSharePrice) {
      desiredSharePrice = actualSharePrice;
    }
    uint256 sharePriceDifference = desiredSharePrice.sub(actualSharePrice);
    return sharePriceToUsdc(sharePriceDifference, totalShares);
  }

  function applyToSharePrice(
    uint256 amountRemaining,
    uint256 currentSharePrice,
    uint256 desiredAmount,
    uint256 totalShares
  ) public pure returns (uint256, uint256) {
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

  function scaleByPercentOwnership(
    ITranchedPool.TrancheInfo memory tranche,
    uint256 amount,
    ITranchedPool.PoolSlice memory slice
  ) public pure returns (uint256) {
    uint256 totalDeposited = slice.juniorTranche.principalDeposited.add(slice.seniorTranche.principalDeposited);
    return scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
  }
}