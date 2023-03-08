// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    TwoTokenPoolContext, 
    StrategyContext, 
    DepositTradeParams, 
    TradeParams,
    SingleSidedRewardTradeParams,
    Proportional2TokenRewardTradeParams,
    RedeemParams
} from "../../VaultTypes.sol";
import {VaultConstants} from "../../VaultConstants.sol";
import {StrategyUtils} from "../strategy/StrategyUtils.sol";
import {RewardUtils} from "../reward/RewardUtils.sol";
import {Errors} from "../../../../global/Errors.sol";
import {ITradingModule} from "../../../../../interfaces/trading/ITradingModule.sol";
import {IERC20} from "../../../../../interfaces/IERC20.sol";

library TwoTokenPoolUtils {
    using StrategyUtils for StrategyContext;

    /// @notice Gets the oracle price pair price between two tokens using a weighted
    /// average between a chainlink oracle and the balancer TWAP oracle.
    /// @param poolContext oracle context variables
    /// @param strategyContext strategy context variables
    /// @return oraclePairPrice oracle price for the pair in 18 decimals
    function _getOraclePairPrice(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext
    ) internal view returns (uint256 oraclePairPrice) {
        (int256 rate, int256 decimals) = strategyContext.tradingModule.getOraclePrice(
            poolContext.primaryToken, poolContext.secondaryToken
        );
        require(rate > 0);
        require(decimals >= 0);

        if (uint256(decimals) != strategyContext.poolClaimPrecision) {
            rate = (rate * int256(strategyContext.poolClaimPrecision)) / decimals;
        }

        // No overflow in rate conversion, checked above
        oraclePairPrice = uint256(rate);
    }

    /// @notice calculates the expected primary and secondary amounts based on
    /// the given spot price and oracle price
    function _getMinExitAmounts(
        TwoTokenPoolContext calldata poolContext,
        StrategyContext calldata strategyContext,
        uint256 spotPrice,
        uint256 oraclePrice,
        uint256 poolClaim
    ) internal view returns (uint256 minPrimary, uint256 minSecondary) {
        strategyContext._checkPriceLimit(oraclePrice, spotPrice);

        // min amounts are calculated based on the share of the Balancer pool with a small discount applied
        uint256 totalPoolSupply = poolContext.poolToken.totalSupply();
        minPrimary = (poolContext.primaryBalance * poolClaim * 
            strategyContext.vaultSettings.poolSlippageLimitPercent) / 
            (totalPoolSupply * uint256(VaultConstants.VAULT_PERCENT_BASIS));
        minSecondary = (poolContext.secondaryBalance * poolClaim * 
            strategyContext.vaultSettings.poolSlippageLimitPercent) / 
            (totalPoolSupply * uint256(VaultConstants.VAULT_PERCENT_BASIS));
    }

    function _getTimeWeightedPrimaryBalance(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        uint256 poolClaim,
        uint256 oraclePrice,
        uint256 spotPrice
    ) internal view returns (uint256 primaryAmount) {
        // Make sure spot price is within oracleDeviationLimit of pairPrice
        strategyContext._checkPriceLimit(oraclePrice, spotPrice);
        
        // Get shares of primary and secondary balances with the provided poolClaim
        uint256 totalSupply = poolContext.poolToken.totalSupply();
        uint256 primaryBalance = poolContext.primaryBalance * poolClaim / totalSupply;
        uint256 secondaryBalance = poolContext.secondaryBalance * poolClaim / totalSupply;

        // Value the secondary balance in terms of the primary token using the oraclePairPrice
        uint256 secondaryAmountInPrimary = secondaryBalance * strategyContext.poolClaimPrecision / oraclePrice;

        // Make sure primaryAmount is reported in primaryPrecision
        uint256 primaryPrecision = 10 ** poolContext.primaryDecimals;
        primaryAmount = (primaryBalance + secondaryAmountInPrimary) * primaryPrecision / strategyContext.poolClaimPrecision;
    }

    /// @notice Trade primary currency for secondary if the trade is specified
    function _tradePrimaryForSecondary(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        bytes memory data
    ) internal returns (uint256 primarySold, uint256 secondaryBought) {
        (DepositTradeParams memory params) = abi.decode(data, (DepositTradeParams));

        (primarySold, secondaryBought) = StrategyUtils._executeTradeExactIn({
            params: params.tradeParams, 
            tradingModule: strategyContext.tradingModule, 
            sellToken: poolContext.primaryToken, 
            buyToken: poolContext.secondaryToken, 
            amount: params.tradeAmount,
            useDynamicSlippage: true
        });
    }

    function _sellSecondaryBalance(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        RedeemParams memory params,
        uint256 secondaryBalance
    ) internal returns (uint256 primaryPurchased) {
        (TradeParams memory tradeParams) = abi.decode(
            params.secondaryTradeParams, (TradeParams)
        );

        ( /*uint256 amountSold */, primaryPurchased) = 
            StrategyUtils._executeTradeExactIn({
                params: tradeParams,
                tradingModule: strategyContext.tradingModule,
                sellToken: poolContext.secondaryToken,
                buyToken: poolContext.primaryToken,
                amount: secondaryBalance,
                useDynamicSlippage: true
            });
    }

    function _validateTrades(
        IERC20[] memory rewardTokens,
        SingleSidedRewardTradeParams memory primaryTrade,
        SingleSidedRewardTradeParams memory secondaryTrade,
        address primaryToken,
        address secondaryToken
    ) private pure {
        // Validate trades
        if (!RewardUtils._isValidRewardToken(rewardTokens, primaryTrade.sellToken)) {
            revert Errors.InvalidRewardToken(primaryTrade.sellToken);
        }
        if (secondaryTrade.sellToken != primaryTrade.sellToken) {
            revert Errors.InvalidRewardToken(secondaryTrade.sellToken);
        }
        if (primaryTrade.buyToken != primaryToken) {
            revert Errors.InvalidRewardToken(primaryTrade.buyToken);
        }
        if (secondaryTrade.buyToken != secondaryToken) {
            revert Errors.InvalidRewardToken(secondaryTrade.buyToken);
        }
    }

    function _executeRewardTrades(
        TwoTokenPoolContext calldata poolContext,
        IERC20[] memory rewardTokens,
        ITradingModule tradingModule,
        bytes calldata data
    ) internal returns (address rewardToken, uint256 primaryAmount, uint256 secondaryAmount) {
        Proportional2TokenRewardTradeParams memory params = abi.decode(
            data,
            (Proportional2TokenRewardTradeParams)
        );

        _validateTrades(
            rewardTokens,
            params.primaryTrade,
            params.secondaryTrade,
            poolContext.primaryToken,
            poolContext.secondaryToken
        );

        (/*uint256 amountSold*/, primaryAmount) = StrategyUtils._executeTradeExactIn({
            params: params.primaryTrade.tradeParams,
            tradingModule: tradingModule,
            sellToken: params.primaryTrade.sellToken,
            buyToken: params.primaryTrade.buyToken,
            amount: params.primaryTrade.amount,
            useDynamicSlippage: false
        });

        (/*uint256 amountSold*/, secondaryAmount) = StrategyUtils._executeTradeExactIn({
            params: params.secondaryTrade.tradeParams,
            tradingModule: tradingModule,
            sellToken: params.secondaryTrade.sellToken,
            buyToken: params.secondaryTrade.buyToken,
            amount: params.secondaryTrade.amount,
            useDynamicSlippage: false
        });

        rewardToken = params.primaryTrade.sellToken;
    }
}