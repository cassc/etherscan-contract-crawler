// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {StableOracleContext, Balancer2TokenPoolContext, StrategyContext} from "../../BalancerVaultTypes.sol";
import {TwoTokenPoolContext} from "../../../common/VaultTypes.sol";
import {VaultConstants} from "../../../common/VaultConstants.sol";
import {StrategyUtils} from "../../../common/internal/strategy/StrategyUtils.sol";
import {TwoTokenPoolUtils} from "../../../common/internal/pool/TwoTokenPoolUtils.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Errors} from "../../../../global/Errors.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {StableMath} from "./StableMath.sol";
import {ITradingModule} from "../../../../../interfaces/trading/ITradingModule.sol";

library Stable2TokenOracleMath {
    using TypeConvert for int256;
    using Stable2TokenOracleMath for StableOracleContext;
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using StrategyUtils for StrategyContext;

    function _getSpotPrice(
        StableOracleContext memory oracleContext, 
        Balancer2TokenPoolContext memory poolContext, 
        uint256 primaryBalance,
        uint256 secondaryBalance,
        uint256 tokenIndex
    ) internal view returns (uint256 spotPrice) {
        require(tokenIndex < 2); /// @dev invalid token index

        /// Apply scale factors
        uint256 scaledPrimaryBalance = primaryBalance * poolContext.primaryScaleFactor 
            / BalancerConstants.BALANCER_PRECISION;
        uint256 scaledSecondaryBalance = secondaryBalance * poolContext.secondaryScaleFactor 
            / BalancerConstants.BALANCER_PRECISION;

        /// @notice poolContext balances are always in BALANCER_PRECISION (1e18)
        (uint256 balanceX, uint256 balanceY) = tokenIndex == 0 ?
            (scaledPrimaryBalance, scaledSecondaryBalance) :
            (scaledSecondaryBalance, scaledPrimaryBalance);

        uint256 invariant = StableMath._calculateInvariant(
            oracleContext.ampParam, StableMath._balances(balanceX, balanceY), true // round up
        );

        spotPrice = StableMath._calcSpotPrice({
            amplificationParameter: oracleContext.ampParam,
            invariant: invariant,
            balanceX: balanceX,
            balanceY: balanceY
        });

        /// Apply secondary scale factor in reverse
        uint256 scaleFactor = tokenIndex == 0 ?
            poolContext.secondaryScaleFactor * BalancerConstants.BALANCER_PRECISION / poolContext.primaryScaleFactor :
            poolContext.primaryScaleFactor * BalancerConstants.BALANCER_PRECISION / poolContext.secondaryScaleFactor;
        spotPrice = spotPrice * BalancerConstants.BALANCER_PRECISION / scaleFactor;

        // Convert precision back to 1e18 after downscaling by scaleFactor
        spotPrice = spotPrice * BalancerConstants.BALANCER_PRECISION / _getPrecision(poolContext.basePool, tokenIndex);
    }

    function _getPrecision(
        TwoTokenPoolContext memory poolContext,
        uint256 tokenIndex
    ) private pure returns(uint256 precision) {
        if (tokenIndex == 0) {
            precision = 10**poolContext.primaryDecimals;
        } else if (tokenIndex == 1) {
            precision = 10**poolContext.secondaryDecimals;
        }
    }

    /// @notice calculates the expected min exit amounts for a given BPT amount
    function _getMinExitAmounts(
        StableOracleContext calldata oracleContext,
        Balancer2TokenPoolContext calldata poolContext,
        StrategyContext calldata strategyContext,
        uint256 oraclePrice,
        uint256 bptAmount
    ) internal view returns (uint256 minPrimary, uint256 minSecondary) {
        // Oracle price is always specified in terms of primary, so tokenIndex == 0 for primary
        // Validate the spot price to make sure the pool is not being manipulated
        uint256 spotPrice = _getSpotPrice({
            oracleContext: oracleContext,
            poolContext: poolContext,
            primaryBalance: poolContext.basePool.primaryBalance,
            secondaryBalance: poolContext.basePool.secondaryBalance,
            tokenIndex: 0
        });

        (minPrimary, minSecondary) = poolContext.basePool._getMinExitAmounts({
            strategyContext: strategyContext,
            spotPrice: spotPrice,
            oraclePrice: oraclePrice,
            poolClaim: bptAmount
        });
    }

    function _validateSpotPriceAndPairPrice(
        StableOracleContext calldata oracleContext,
        Balancer2TokenPoolContext calldata poolContext,
        StrategyContext memory strategyContext,
        uint256 oraclePrice,
        uint256 primaryAmount, 
        uint256 secondaryAmount
    ) internal view {
        // Oracle price is always specified in terms of primary, so tokenIndex == 0 for primary
        uint256 spotPrice = _getSpotPrice({
            oracleContext: oracleContext,
            poolContext: poolContext,
            primaryBalance: poolContext.basePool.primaryBalance,
            secondaryBalance: poolContext.basePool.secondaryBalance,
            tokenIndex: 0
        });

        /// @notice Check spotPrice against oracle price to make sure that 
        /// the pool is not being manipulated
        strategyContext._checkPriceLimit(oraclePrice, spotPrice);

        uint256 calculatedPairPrice = _getSpotPrice({
            oracleContext: oracleContext,
            poolContext: poolContext,
            primaryBalance: primaryAmount,
            secondaryBalance: secondaryAmount,
            tokenIndex: 0
        });

        /// @notice Check the calculated primary/secondary price against the oracle price
        /// to make sure that we are joining the pool proportionally
        strategyContext._checkPriceLimit(oraclePrice, calculatedPairPrice);
    }
}