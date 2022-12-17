// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    Balanced2TokenRewardTradeParams,
    SingleSidedRewardTradeParams,
    ReinvestRewardParams,
    StrategyContext,
    PoolContext,
    AuraStakingContext,
    TwoTokenPoolContext
} from "../../BalancerVaultTypes.sol";
import {Errors} from "../../../../global/Errors.sol";
import {BalancerEvents} from "../../BalancerEvents.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {BalancerUtils} from "../pool/BalancerUtils.sol";
import {ITradingModule} from "../../../../../interfaces/trading/ITradingModule.sol";
import {TwoTokenPoolUtils} from "../pool/TwoTokenPoolUtils.sol";
import {StrategyUtils} from "../strategy/StrategyUtils.sol";
import {AuraStakingUtils} from "../staking/AuraStakingUtils.sol";

library TwoTokenAuraRewardUtils {
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using AuraStakingUtils for AuraStakingContext;

    function _validateTrades(
        AuraStakingContext calldata context,
        SingleSidedRewardTradeParams memory primaryTrade,
        SingleSidedRewardTradeParams memory secondaryTrade,
        address primaryToken,
        address secondaryToken
    ) private pure {
        // Validate trades
        if (!context._isValidRewardToken(primaryTrade.sellToken)) {
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
        AuraStakingContext calldata stakingContext,
        ITradingModule tradingModule,
        bytes calldata data,
        uint256 slippageLimit
    ) internal returns (address rewardToken, uint256 primaryAmount, uint256 secondaryAmount) {
        Balanced2TokenRewardTradeParams memory params = abi.decode(
            data,
            (Balanced2TokenRewardTradeParams)
        );

        _validateTrades(
            stakingContext,
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