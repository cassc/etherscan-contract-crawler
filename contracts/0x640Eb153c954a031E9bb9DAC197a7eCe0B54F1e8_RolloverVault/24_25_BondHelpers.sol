// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IBondController } from "../_interfaces/buttonwood/IBondController.sol";
import { ITranche } from "../_interfaces/buttonwood/ITranche.sol";

import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

/// @notice Expected tranche to be part of bond.
/// @param tranche Address of the tranche token.
error UnacceptableTranche(ITranche tranche);

struct BondTranches {
    ITranche[] tranches;
    uint256[] trancheRatios;
}

/**
 *  @title BondTranchesHelpers
 *
 *  @notice Library with helper functions for the bond's retrieved tranche data.
 *
 */
library BondTranchesHelpers {
    /// @notice Iterates through the tranche data to find the seniority index of the given tranche.
    /// @param bt The tranche data object.
    /// @param t The address of the tranche to check.
    /// @return the index of the tranche in the tranches array.
    function indexOf(BondTranches memory bt, ITranche t) internal pure returns (uint8) {
        for (uint8 i = 0; i < bt.tranches.length; i++) {
            if (bt.tranches[i] == t) {
                return i;
            }
        }
        revert UnacceptableTranche(t);
    }
}

/**
 *  @title TrancheHelpers
 *
 *  @notice Library with helper functions for tranche tokens.
 *
 */
library TrancheHelpers {
    /// @notice Given a tranche, looks up the collateral balance backing the tranche supply.
    /// @param t Address of the tranche token.
    /// @return The collateral balance and the tranche token supply.
    function getTrancheCollateralization(ITranche t) internal view returns (uint256, uint256) {
        IBondController bond = IBondController(t.bond());
        BondTranches memory bt;
        uint256[] memory collateralBalances;
        uint256[] memory trancheSupplies;
        (bt, collateralBalances, trancheSupplies) = BondHelpers.getTrancheCollateralizations(bond);
        uint256 trancheIndex = BondTranchesHelpers.indexOf(bt, t);
        return (collateralBalances[trancheIndex], trancheSupplies[trancheIndex]);
    }
}

/**
 *  @title BondHelpers
 *
 *  @notice Library with helper functions for ButtonWood's Bond contract.
 *
 */
library BondHelpers {
    using SafeCastUpgradeable for uint256;
    using MathUpgradeable for uint256;

    // Replicating value used here:
    // https://github.com/buttonwood-protocol/tranche/blob/main/contracts/BondController.sol
    uint256 private constant TRANCHE_RATIO_GRANULARITY = 1000;
    uint256 private constant BPS = 10_000;

    /// @notice Given a bond, calculates the time remaining to maturity.
    /// @param b The address of the bond contract.
    /// @return The number of seconds before the bond reaches maturity.
    function secondsToMaturity(IBondController b) internal view returns (uint256) {
        uint256 maturityDate = b.maturityDate();
        return maturityDate > block.timestamp ? maturityDate - block.timestamp : 0;
    }

    /// @notice Given a bond, retrieves all of the bond's tranches.
    /// @param b The address of the bond contract.
    /// @return The tranche data.
    function getTranches(IBondController b) internal view returns (BondTranches memory) {
        BondTranches memory bt;
        uint8 trancheCount = b.trancheCount().toUint8();
        bt.tranches = new ITranche[](trancheCount);
        bt.trancheRatios = new uint256[](trancheCount);
        // Max tranches per bond < 2**8 - 1
        for (uint8 i = 0; i < trancheCount; i++) {
            (ITranche t, uint256 ratio) = b.tranches(i);
            bt.tranches[i] = t;
            bt.trancheRatios[i] = ratio;
        }
        return bt;
    }

    /// @notice Given a bond, returns the tranche at the specified index.
    /// @param b The address of the bond contract.
    /// @param i Index of the tranche.
    /// @return t The tranche address.
    function trancheAt(IBondController b, uint8 i) internal view returns (ITranche t) {
        (t, ) = b.tranches(i);
        return t;
    }

    /// @notice Helper function to estimate the amount of tranches minted when a given amount of collateral
    ///         is deposited into the bond.
    /// @dev This function is used off-chain services (using callStatic) to preview tranches minted after
    /// @param b The address of the bond contract.
    /// @return The tranche data, an array of tranche amounts and fees.
    function previewDeposit(IBondController b, uint256 collateralAmount)
        internal
        view
        returns (
            BondTranches memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        BondTranches memory bt = getTranches(b);
        uint256[] memory trancheAmts = new uint256[](bt.tranches.length);
        uint256[] memory fees = new uint256[](bt.tranches.length);

        uint256 totalDebt = b.totalDebt();
        uint256 collateralBalance = IERC20Upgradeable(b.collateralToken()).balanceOf(address(b));
        uint256 feeBps = b.feeBps();

        for (uint8 i = 0; i < bt.tranches.length; i++) {
            trancheAmts[i] = collateralAmount.mulDiv(bt.trancheRatios[i], TRANCHE_RATIO_GRANULARITY);
            if (collateralBalance > 0) {
                trancheAmts[i] = trancheAmts[i].mulDiv(totalDebt, collateralBalance);
            }
        }

        if (feeBps > 0) {
            for (uint8 i = 0; i < bt.tranches.length; i++) {
                fees[i] = trancheAmts[i].mulDiv(feeBps, BPS);
                trancheAmts[i] -= fees[i];
            }
        }

        return (bt, trancheAmts, fees);
    }

    /// @notice Given a bond, for each tranche token retrieves the total collateral redeemable
    ///         for the total supply of the tranche token (aka debt issued).
    /// @dev The cdr can be computed for each tranche by dividing the
    ///      returned tranche's collateralBalance by the tranche's totalSupply.
    /// @param b The address of the bond contract.
    /// @return The tranche data and the list of collateral balances and the total supplies for each tranche.
    function getTrancheCollateralizations(IBondController b)
        internal
        view
        returns (
            BondTranches memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        BondTranches memory bt = getTranches(b);
        uint256[] memory collateralBalances = new uint256[](bt.tranches.length);
        uint256[] memory trancheSupplies = new uint256[](bt.tranches.length);

        // When the bond is mature, the collateral is transferred over to the individual tranche token contracts
        if (b.isMature()) {
            for (uint8 i = 0; i < bt.tranches.length; i++) {
                trancheSupplies[i] = bt.tranches[i].totalSupply();
                collateralBalances[i] = IERC20Upgradeable(b.collateralToken()).balanceOf(address(bt.tranches[i]));
            }
            return (bt, collateralBalances, trancheSupplies);
        }

        // Before the bond is mature, all the collateral is held by the bond contract
        uint256 bondCollateralBalance = IERC20Upgradeable(b.collateralToken()).balanceOf(address(b));
        uint256 zTrancheIndex = bt.tranches.length - 1;
        for (uint8 i = 0; i < bt.tranches.length; i++) {
            trancheSupplies[i] = bt.tranches[i].totalSupply();

            // a to y tranches
            if (i != zTrancheIndex) {
                collateralBalances[i] = (trancheSupplies[i] <= bondCollateralBalance)
                    ? trancheSupplies[i]
                    : bondCollateralBalance;
                bondCollateralBalance -= collateralBalances[i];
            }
            // z tranche
            else {
                collateralBalances[i] = bondCollateralBalance;
            }
        }

        return (bt, collateralBalances, trancheSupplies);
    }

    /// @notice For a given bond and user address, computes the maximum number of each of the bond's tranches
    ///         the user is able to redeem before the bond's maturity. These tranche amounts necessarily match the bond's tranche ratios.
    /// @param b The address of the bond contract.
    /// @param u The address to check balance for.
    /// @return The tranche data and an array of tranche token balances.
    function computeRedeemableTrancheAmounts(IBondController b, address u)
        internal
        view
        returns (BondTranches memory, uint256[] memory)
    {
        BondTranches memory bt = getTranches(b);
        uint256[] memory redeemableAmts = new uint256[](bt.tranches.length);

        // Calculate how many underlying assets could be redeemed from each tranche balance,
        // assuming other tranches are not an issue, and record the smallest amount.
        uint256 minUnderlyingOut = type(uint256).max;
        uint8 i;
        for (i = 0; i < bt.tranches.length; i++) {
            uint256 d = bt.tranches[i].balanceOf(u).mulDiv(TRANCHE_RATIO_GRANULARITY, bt.trancheRatios[i]);
            if (d < minUnderlyingOut) {
                minUnderlyingOut = d;
            }

            // if one of the balances is zero, we return
            if (minUnderlyingOut == 0) {
                return (bt, redeemableAmts);
            }
        }

        for (i = 0; i < bt.tranches.length; i++) {
            redeemableAmts[i] = bt.trancheRatios[i].mulDiv(minUnderlyingOut, TRANCHE_RATIO_GRANULARITY);
        }

        return (bt, redeemableAmts);
    }
}