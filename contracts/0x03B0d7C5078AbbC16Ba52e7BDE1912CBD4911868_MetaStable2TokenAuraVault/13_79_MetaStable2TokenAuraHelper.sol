// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    MetaStable2TokenAuraStrategyContext,
    StableOracleContext,
    StrategyContext,
    TwoTokenPoolContext,
    DepositParams,
    RedeemParams,
    ReinvestRewardParams,
    StrategyVaultSettings,
    StrategyVaultState
} from "../BalancerVaultTypes.sol";
import {BalancerEvents} from "../BalancerEvents.sol";
import {SettlementUtils} from "../internal/settlement/SettlementUtils.sol";
import {StrategyUtils} from "../internal/strategy/StrategyUtils.sol";
import {TwoTokenPoolUtils} from "../internal/pool/TwoTokenPoolUtils.sol";
import {TwoTokenAuraRewardUtils} from "../internal/reward/TwoTokenAuraRewardUtils.sol";
import {Stable2TokenOracleMath} from "../internal/math/Stable2TokenOracleMath.sol";
import {BalancerVaultStorage} from "../internal/BalancerVaultStorage.sol";
import {IERC20} from "../../../../interfaces/IERC20.sol";

library MetaStable2TokenAuraHelper {
    using TwoTokenAuraRewardUtils for TwoTokenPoolContext;
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using Stable2TokenOracleMath for StableOracleContext;
    using StrategyUtils for StrategyContext;
    using SettlementUtils for StrategyContext;
    using BalancerVaultStorage for StrategyVaultSettings;
    using BalancerVaultStorage for StrategyVaultState;

    function deposit(
        MetaStable2TokenAuraStrategyContext memory context,
        uint256 deposit,
        bytes calldata data
    ) external returns (uint256 strategyTokensMinted) {
        DepositParams memory params = abi.decode(data, (DepositParams));

        strategyTokensMinted = context.poolContext._deposit({
            strategyContext: context.baseStrategy,
            stakingContext: context.stakingContext,
            deposit: deposit,
            params: params
        });
    }

    function redeem(
        MetaStable2TokenAuraStrategyContext memory context,
        uint256 strategyTokens,
        bytes calldata data
    ) external returns (uint256 finalPrimaryBalance) {
        RedeemParams memory params = abi.decode(data, (RedeemParams));

        finalPrimaryBalance = context.poolContext._redeem({
            strategyContext: context.baseStrategy,
            stakingContext: context.stakingContext,
            strategyTokens: strategyTokens,
            params: params
        });
    }

    function settleVault(
        MetaStable2TokenAuraStrategyContext calldata context,
        uint256 maturity,
        uint256 strategyTokensToRedeem,
        RedeemParams memory params
    ) external {
        uint256 bptToSettle = context.baseStrategy._convertStrategyTokensToBPTClaim(strategyTokensToRedeem);
        
        _executeSettlement({
            strategyContext: context.baseStrategy,
            oracleContext: context.oracleContext,
            poolContext: context.poolContext,
            maturity: maturity,
            bptToSettle: bptToSettle,
            redeemStrategyTokenAmount: strategyTokensToRedeem,
            params: params
        });

        emit BalancerEvents.VaultSettlement(maturity, bptToSettle, strategyTokensToRedeem);
    }

    function settleVaultEmergency(
        MetaStable2TokenAuraStrategyContext calldata context, 
        uint256 maturity, 
        bytes calldata data
    ) external {
        RedeemParams memory params = SettlementUtils._decodeParamsAndValidate(
            context.baseStrategy.vaultSettings.emergencySettlementSlippageLimitPercent,
            data
        );

        uint256 bptToSettle = context.baseStrategy._getEmergencySettlementParams({
            maturity: maturity, 
            totalBPTSupply: IERC20(context.poolContext.basePool.pool).totalSupply()
        });

        uint256 redeemStrategyTokenAmount = 
            context.baseStrategy._convertBPTClaimToStrategyTokens(bptToSettle);

        _executeSettlement({
            strategyContext: context.baseStrategy,
            oracleContext: context.oracleContext,
            poolContext: context.poolContext,
            maturity: maturity,
            bptToSettle: bptToSettle,
            redeemStrategyTokenAmount: redeemStrategyTokenAmount,
            params: params
        });

        emit BalancerEvents.EmergencyVaultSettlement(maturity, bptToSettle, redeemStrategyTokenAmount);
    }

    function _executeSettlement(
        StrategyContext calldata strategyContext,
        StableOracleContext calldata oracleContext,
        TwoTokenPoolContext calldata poolContext,
        uint256 maturity,
        uint256 bptToSettle,
        uint256 redeemStrategyTokenAmount,
        RedeemParams memory params
    ) private {
        uint256 oraclePrice = poolContext._getOraclePairPrice(strategyContext.tradingModule);

        /// @notice params.minPrimary and params.minSecondary are not required for this strategy vault
        (params.minPrimary, params.minSecondary) = oracleContext._getMinExitAmounts({
            poolContext: poolContext,
            strategyContext: strategyContext,
            oraclePrice: oraclePrice,
            bptAmount: bptToSettle
        });

        int256 expectedUnderlyingRedeemed = poolContext._convertStrategyToUnderlying({
            strategyContext: strategyContext,
            oracleContext: oracleContext,
            strategyTokenAmount: redeemStrategyTokenAmount
        });

        strategyContext._executeSettlement({
            maturity: maturity,
            expectedUnderlyingRedeemed: expectedUnderlyingRedeemed,
            redeemStrategyTokenAmount: redeemStrategyTokenAmount,
            params: params
        });
    }

    function reinvestReward(
        MetaStable2TokenAuraStrategyContext calldata context,
        ReinvestRewardParams calldata params
    ) external {
        StrategyContext memory strategyContext = context.baseStrategy;
        TwoTokenPoolContext calldata poolContext = context.poolContext; 
        StableOracleContext calldata oracleContext = context.oracleContext;

        (
            address rewardToken, 
            uint256 primaryAmount, 
            uint256 secondaryAmount
        ) = poolContext._executeRewardTrades(
            context.stakingContext,
            strategyContext.tradingModule,
            params.tradeData,
            strategyContext.vaultSettings.maxRewardTradeSlippageLimitPercent
        );

        // Make sure we are joining with the right proportion to minimize slippage
        oracleContext._validateSpotPriceAndPairPrice({
            poolContext: poolContext,
            strategyContext: strategyContext,
            oraclePrice: poolContext._getOraclePairPrice(strategyContext.tradingModule),
            primaryAmount: primaryAmount,
            secondaryAmount: secondaryAmount
        });

        uint256 bptAmount = poolContext._joinPoolAndStake({
            strategyContext: strategyContext,
            stakingContext: context.stakingContext,
            primaryAmount: primaryAmount,
            secondaryAmount: secondaryAmount,
            /// @notice minBPT is not required to be set by the caller because primaryAmount
            /// and secondaryAmount are already validated
            minBPT: params.minBPT        
        });

        strategyContext.vaultState.totalBPTHeld += bptAmount;
        strategyContext.vaultState.setStrategyVaultState(); 

        emit BalancerEvents.RewardReinvested(rewardToken, primaryAmount, secondaryAmount, bptAmount); 
    }
}