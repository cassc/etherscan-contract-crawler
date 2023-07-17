// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

import { Math } from "./math/Math.sol";
import { WadRayMath } from "./math/WadRayMath.sol";
import { PercentageMath } from "./math/PercentageMath.sol";

/// @title Utils
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Utils for Morpho-Aave V3's Snippets.
library Utils {
    using Math for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    struct P2PRateComputeParams {
        uint256 poolSupplyRatePerYear;
        uint256 poolBorrowRatePerYear;
        uint256 poolIndex;
        uint256 p2pIndex;
        uint256 proportionIdle;
        uint256 p2pDelta;
        uint256 p2pTotal;
        uint256 p2pIndexCursor;
        uint256 reserveFactor;
    }

    /// @dev Returns the rate experienced based on a given pool & peer-to-peer distribution.
    /// @param p2pRate The peer-to-peer rate (in a unit common to `poolRate` & `globalRate`).
    /// @param poolRate The pool rate (in a unit common to `p2pRate` & `globalRate`).
    /// @param balanceInP2P The amount of balance matched peer-to-peer (in a unit common to `balanceOnPool`).
    /// @param balanceOnPool The amount of balance supplied on pool (in a unit common to `balanceInP2P`).
    /// @return globalRate The rate experienced by the given distribution (in a unit common to `p2pRate` & `poolRate`).
    function weightedRate(
        uint256 p2pRate,
        uint256 poolRate,
        uint256 balanceInP2P,
        uint256 balanceOnPool
    ) internal pure returns (uint256 globalRate) {
        uint256 totalBalance = balanceInP2P + balanceOnPool;
        if (totalBalance == 0) return (globalRate);

        if (balanceInP2P > 0) globalRate += p2pRate.rayMul(balanceInP2P.rayDiv(totalBalance));
        if (balanceOnPool > 0) {
            globalRate += poolRate.rayMul(balanceOnPool.rayDiv(totalBalance));
        }
    }

    /// @notice Computes and returns the peer-to-peer borrow rate per year of a market given its parameters.
    /// @param params The computation parameters.
    /// @return p2pBorrowRate The peer-to-peer borrow rate per year (in ray).
    function p2pBorrowAPR(P2PRateComputeParams memory params) internal pure returns (uint256 p2pBorrowRate) {
        if (params.poolSupplyRatePerYear > params.poolBorrowRatePerYear) {
            // The p2pBorrowRate is set to the poolBorrowRatePerYear because there is no rate spread.
            p2pBorrowRate = params.poolBorrowRatePerYear;
        } else {
            uint256 p2pRate = PercentageMath.weightedAvg(
                params.poolSupplyRatePerYear,
                params.poolBorrowRatePerYear,
                params.p2pIndexCursor
            );
            p2pBorrowRate = p2pRate + (params.poolBorrowRatePerYear - p2pRate).percentMul(params.reserveFactor);
        }

        if (params.p2pDelta > 0 && params.p2pTotal > 0) {
            uint256 proportionDelta = Math.min(
                // Using ray division of an amount in underlying decimals by an
                // amount in underlying decimals yields a value in ray.
                params.p2pDelta.rayMul(params.poolIndex).rayDivUp(params.p2pTotal.rayMul(params.p2pIndex)),
                WadRayMath.RAY // To avoid proportionDelta > 1 with rounding errors.
            ); // In ray.

            p2pBorrowRate =
                p2pBorrowRate.rayMul(WadRayMath.RAY - proportionDelta) +
                params.poolBorrowRatePerYear.rayMul(proportionDelta);
        }
    }

    /// @notice Computes and returns the peer-to-peer supply rate per year of a market given its parameters.
    /// @param params The computation parameters.
    /// @return p2pSupplyRate The peer-to-peer supply rate per year (in ray).
    function p2pSupplyAPR(P2PRateComputeParams memory params) internal pure returns (uint256 p2pSupplyRate) {
        if (params.poolSupplyRatePerYear > params.poolBorrowRatePerYear) {
            // The p2pSupplyRate is set to the poolBorrowRatePerYear because there is no rate spread.
            p2pSupplyRate = params.poolBorrowRatePerYear;
        } else {
            uint256 p2pRate = PercentageMath.weightedAvg(
                params.poolSupplyRatePerYear,
                params.poolBorrowRatePerYear,
                params.p2pIndexCursor
            );

            p2pSupplyRate = p2pRate - (p2pRate - params.poolSupplyRatePerYear).percentMul(params.reserveFactor);
        }

        if ((params.p2pDelta > 0 || params.proportionIdle > 0) && params.p2pTotal > 0) {
            uint256 proportionDelta = Math.min(
                // Using ray division of an amount in underlying decimals by an
                // amount in underlying decimals yields a value in ray.
                params.p2pDelta.rayMul(params.poolIndex).rayDivUp(params.p2pTotal.rayMul(params.p2pIndex)),
                // To avoid proportionDelta > 1 - proportionIdle with rounding errors.
                WadRayMath.RAY - params.proportionIdle
            ); // In ray.

            p2pSupplyRate =
                p2pSupplyRate.rayMul(WadRayMath.RAY - proportionDelta - params.proportionIdle) +
                params.poolSupplyRatePerYear.rayMul(proportionDelta);
        }
    }
}