// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    TwoTokenPoolContext, 
    StableOracleContext, 
    PoolParams,
    DepositParams,
    TradeParams,
    DepositTradeParams,
    RedeemParams,
    AuraStakingContext,
    StrategyContext,
    StrategyVaultSettings,
    StrategyVaultState
} from "../../BalancerVaultTypes.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Errors} from "../../../../global/Errors.sol";
import {Constants} from "../../../../global/Constants.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {IAsset} from "../../../../../interfaces/balancer/IBalancerVault.sol";
import {TradeHandler} from "../../../../trading/TradeHandler.sol";
import {BalancerUtils} from "../pool/BalancerUtils.sol";
import {Stable2TokenOracleMath} from "../math/Stable2TokenOracleMath.sol";
import {AuraStakingUtils} from "../staking/AuraStakingUtils.sol";
import {BalancerVaultStorage} from "../BalancerVaultStorage.sol";
import {StrategyUtils} from "../strategy/StrategyUtils.sol";
import {TwoTokenPoolUtils} from "../pool/TwoTokenPoolUtils.sol";
import {ITradingModule, Trade} from "../../../../../interfaces/trading/ITradingModule.sol";
import {TokenUtils, IERC20} from "../../../../utils/TokenUtils.sol";

library TwoTokenPoolUtils {
    using TokenUtils for IERC20;
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using TradeHandler for Trade;
    using TypeConvert for uint256;
    using StrategyUtils for StrategyContext;
    using AuraStakingUtils for AuraStakingContext;
    using BalancerVaultStorage for StrategyVaultSettings;
    using BalancerVaultStorage for StrategyVaultState;
    using Stable2TokenOracleMath for StableOracleContext;

    /// @notice Returns parameters for joining and exiting Balancer pools
    function _getPoolParams(
        TwoTokenPoolContext memory context,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        bool isJoin
    ) internal pure returns (PoolParams memory) {
        IAsset[] memory assets = new IAsset[](2);
        assets[context.primaryIndex] = IAsset(context.primaryToken);
        assets[context.secondaryIndex] = IAsset(context.secondaryToken);

        uint256[] memory amounts = new uint256[](2);
        amounts[context.primaryIndex] = primaryAmount;
        amounts[context.secondaryIndex] = secondaryAmount;

        uint256 msgValue;
        if (isJoin && assets[context.primaryIndex] == IAsset(Deployments.ETH_ADDRESS)) {
            msgValue = amounts[context.primaryIndex];
        }

        return PoolParams(assets, amounts, msgValue);
    }

    /// @notice Gets the oracle price pair price between two tokens using a weighted
    /// average between a chainlink oracle and the balancer TWAP oracle.
    /// @param poolContext oracle context variables
    /// @param tradingModule address of the trading module
    /// @return oraclePairPrice oracle price for the pair in 18 decimals
    function _getOraclePairPrice(
        TwoTokenPoolContext memory poolContext,
        ITradingModule tradingModule
    ) internal view returns (uint256 oraclePairPrice) {
        (int256 rate, int256 decimals) = tradingModule.getOraclePrice(
            poolContext.primaryToken, poolContext.secondaryToken
        );
        require(rate > 0);
        require(decimals >= 0);

        if (uint256(decimals) != BalancerConstants.BALANCER_PRECISION) {
            rate = (rate * int256(BalancerConstants.BALANCER_PRECISION)) / decimals;
        }

        // No overflow in rate conversion, checked above
        oraclePairPrice = uint256(rate);
    }

    /// @notice Gets the time-weighted primary token balance for a given bptAmount
    /// @dev Balancer pool needs to be fully initialized with at least 1024 trades
    /// @param poolContext pool context variables
    /// @param oracleContext oracle context variables
    /// @param bptAmount amount of balancer pool lp tokens
    /// @return primaryAmount primary token balance
    function _getTimeWeightedPrimaryBalance(
        TwoTokenPoolContext memory poolContext,
        StableOracleContext memory oracleContext,
        StrategyContext memory strategyContext,
        uint256 bptAmount
    ) internal view returns (uint256 primaryAmount) {
        uint256 oraclePairPrice = _getOraclePairPrice(poolContext, strategyContext.tradingModule);
        // tokenIndex == 0 because _getOraclePairPrice always returns the price in terms of
        // the primary currency
        uint256 spotPrice = oracleContext._getSpotPrice({
            poolContext: poolContext,
            primaryBalance: poolContext.primaryBalance,
            secondaryBalance: poolContext.secondaryBalance,
            tokenIndex: 0
        });

        // Make sure spot price is within oracleDeviationLimit of pairPrice
        Stable2TokenOracleMath._checkPriceLimit(strategyContext, oraclePairPrice, spotPrice);
        
        // Get shares of primary and secondary balances with the provided bptAmount
        uint256 totalBPTSupply = poolContext.basePool.pool.totalSupply();
        uint256 primaryBalance = poolContext.primaryBalance * bptAmount / totalBPTSupply;
        uint256 secondaryBalance = poolContext.secondaryBalance * bptAmount / totalBPTSupply;

        // Value the secondary balance in terms of the primary token using the oraclePairPrice
        uint256 secondaryAmountInPrimary = secondaryBalance * BalancerConstants.BALANCER_PRECISION / oraclePairPrice;

        // Make sure primaryAmount is reported in primaryPrecision
        uint256 primaryPrecision = 10 ** poolContext.primaryDecimals;
        primaryAmount = (primaryBalance + secondaryAmountInPrimary) * primaryPrecision / BalancerConstants.BALANCER_PRECISION;
    }

    function _approveBalancerTokens(TwoTokenPoolContext memory poolContext, address bptSpender) internal {
        IERC20(poolContext.primaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
        IERC20(poolContext.secondaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
        // Allow BPT spender to pull BALANCER_POOL_TOKEN
        IERC20(address(poolContext.basePool.pool)).checkApprove(bptSpender, type(uint256).max);
    }

    /// @notice Trade primary currency for secondary if the trade is specified
    function _tradePrimaryForSecondary(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        bytes memory data
    ) private returns (uint256 primarySold, uint256 secondaryBought) {
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

    function _deposit(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 deposit,
        DepositParams memory params
    ) internal returns (uint256 strategyTokensMinted) {
        uint256 secondaryAmount;
        if (params.tradeData.length != 0) {
            // Allows users to trade on a different DEX instead of Balancer when joining
            (uint256 primarySold, uint256 secondaryBought) = _tradePrimaryForSecondary({
                poolContext: poolContext,
                strategyContext: strategyContext,
                data: params.tradeData
            });
            deposit -= primarySold;
            secondaryAmount = secondaryBought;
        }

        uint256 bptMinted = poolContext._joinPoolAndStake({
            strategyContext: strategyContext,
            stakingContext: stakingContext,
            primaryAmount: deposit,
            secondaryAmount: secondaryAmount,
            minBPT: params.minBPT
        });

        strategyTokensMinted = strategyContext._convertBPTClaimToStrategyTokens(bptMinted);

        strategyContext.vaultState.totalBPTHeld += bptMinted;
        // Update global supply count
        strategyContext.vaultState.totalStrategyTokenGlobal += strategyTokensMinted.toUint80();
        strategyContext.vaultState.setStrategyVaultState(); 
    }

    function _sellSecondaryBalance(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        RedeemParams memory params,
        uint256 secondaryBalance
    ) private returns (uint256 primaryPurchased) {
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

    function _redeem(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 strategyTokens,
        RedeemParams memory params
    ) internal returns (uint256 finalPrimaryBalance) {
        uint256 bptClaim = strategyContext._convertStrategyTokensToBPTClaim(strategyTokens);

        if (bptClaim == 0) return 0;

        // Underlying token balances from exiting the pool
        (uint256 primaryBalance, uint256 secondaryBalance)
            = _unstakeAndExitPool(
                poolContext, stakingContext, bptClaim, params.minPrimary, params.minSecondary
            );

        finalPrimaryBalance = primaryBalance;
        if (secondaryBalance > 0) {
            uint256 primaryPurchased = _sellSecondaryBalance(
                poolContext, strategyContext, params, secondaryBalance
            );

            finalPrimaryBalance += primaryPurchased;
        }

        strategyContext.vaultState.totalBPTHeld -= bptClaim;
        // Update global strategy token balance
        strategyContext.vaultState.totalStrategyTokenGlobal -= strategyTokens.toUint80();
        strategyContext.vaultState.setStrategyVaultState(); 
    }

    function _joinPoolAndStake(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        uint256 minBPT
    ) internal returns (uint256 bptMinted) {
        // prettier-ignore
        PoolParams memory poolParams = poolContext._getPoolParams( 
            primaryAmount, 
            secondaryAmount,
            true // isJoin
        );

        bptMinted = BalancerUtils._joinPoolExactTokensIn({
            context: poolContext.basePool,
            params: poolParams,
            minBPT: minBPT
        });

        // Check BPT threshold to make sure our share of the pool is
        // below maxBalancerPoolShare
        uint256 bptThreshold = strategyContext.vaultSettings._bptThreshold(
            poolContext.basePool.pool.totalSupply()
        );
        uint256 bptHeldAfterJoin = strategyContext.vaultState.totalBPTHeld + bptMinted;
        if (bptHeldAfterJoin > bptThreshold)
            revert Errors.BalancerPoolShareTooHigh(bptHeldAfterJoin, bptThreshold);

        // Transfer token to Aura protocol for boosted staking
        bool success = stakingContext.auraBooster.deposit(stakingContext.auraPoolId, bptMinted, true); // stake = true
        if (!success) revert Errors.StakeFailed();
    }

    function _unstakeAndExitPool(
        TwoTokenPoolContext memory poolContext,
        AuraStakingContext memory stakingContext,
        uint256 bptClaim,
        uint256 minPrimary,
        uint256 minSecondary
    ) internal returns (uint256 primaryBalance, uint256 secondaryBalance) {
        // Withdraw BPT tokens back to the vault for redemption
        bool success = stakingContext.auraRewardPool.withdrawAndUnwrap(bptClaim, false); // claimRewards = false
        if (!success) revert Errors.UnstakeFailed();

        uint256[] memory exitBalances = BalancerUtils._exitPoolExactBPTIn({
            context: poolContext.basePool,
            params: poolContext._getPoolParams(minPrimary, minSecondary, false), // isJoin = false
            bptExitAmount: bptClaim
        });
        
        (primaryBalance, secondaryBalance) 
            = (exitBalances[poolContext.primaryIndex], exitBalances[poolContext.secondaryIndex]);
    }

    /// @notice We value strategy tokens in terms of the primary balance. The time weighted
    /// primary balance is used in order to prevent pool manipulation.
    /// @param poolContext pool context variables
    /// @param oracleContext oracle context variables
    /// @param strategyTokenAmount amount of strategy tokens
    /// @return underlyingValue underlying value of strategy tokens
    function _convertStrategyToUnderlying(
        TwoTokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        StableOracleContext memory oracleContext,
        uint256 strategyTokenAmount
    ) internal view returns (int256 underlyingValue) {
        
        uint256 bptClaim 
            = strategyContext._convertStrategyTokensToBPTClaim(strategyTokenAmount);

        underlyingValue 
            = poolContext._getTimeWeightedPrimaryBalance(oracleContext, strategyContext, bptClaim).toInt();
    }
}