// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    Balancer2TokenPoolContext, 
    StableOracleContext, 
    PoolParams,
    AuraStakingContext
} from "../../BalancerVaultTypes.sol";
import {
    TradeParams,
    StrategyContext,
    StrategyVaultSettings,
    StrategyVaultState,
    TwoTokenPoolContext,
    DepositParams,
    RedeemParams
} from "../../../common/VaultTypes.sol";
import {Deployments} from "../../../../global/Deployments.sol";
import {BalancerConstants} from "../BalancerConstants.sol";
import {Errors} from "../../../../global/Errors.sol";
import {Constants} from "../../../../global/Constants.sol";
import {TypeConvert} from "../../../../global/TypeConvert.sol";
import {IAsset} from "../../../../../interfaces/balancer/IBalancerVault.sol";
import {TradeHandler} from "../../../../trading/TradeHandler.sol";
import {BalancerUtils} from "../pool/BalancerUtils.sol";
import {Stable2TokenOracleMath} from "../math/Stable2TokenOracleMath.sol";
import {VaultStorage} from "../../../common/VaultStorage.sol";
import {StrategyUtils} from "../../../common/internal/strategy/StrategyUtils.sol";
import {TwoTokenPoolUtils} from "../../../common/internal/pool/TwoTokenPoolUtils.sol";
import {Balancer2TokenPoolUtils} from "../pool/Balancer2TokenPoolUtils.sol";
import {Trade} from "../../../../../interfaces/trading/ITradingModule.sol";
import {TokenUtils, IERC20} from "../../../../utils/TokenUtils.sol";

library Balancer2TokenPoolUtils {
    using TokenUtils for IERC20;
    using Balancer2TokenPoolUtils for Balancer2TokenPoolContext;
    using TwoTokenPoolUtils for TwoTokenPoolContext;
    using TradeHandler for Trade;
    using TypeConvert for uint256;
    using StrategyUtils for StrategyContext;
    using VaultStorage for StrategyVaultSettings;
    using VaultStorage for StrategyVaultState;
    using Stable2TokenOracleMath for StableOracleContext;

    /// @notice Returns parameters for joining and exiting Balancer pools
    function _getPoolParams(
        Balancer2TokenPoolContext memory context,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        bool isJoin
    ) internal pure returns (PoolParams memory) {
        IAsset[] memory assets = new IAsset[](2);
        assets[context.basePool.primaryIndex] = IAsset(context.basePool.primaryToken);
        assets[context.basePool.secondaryIndex] = IAsset(context.basePool.secondaryToken);

        uint256[] memory amounts = new uint256[](2);
        amounts[context.basePool.primaryIndex] = primaryAmount;
        amounts[context.basePool.secondaryIndex] = secondaryAmount;

        uint256 msgValue;
        if (isJoin && assets[context.basePool.primaryIndex] == IAsset(Deployments.ETH_ADDRESS)) {
            msgValue = amounts[context.basePool.primaryIndex];
        }

        return PoolParams(assets, amounts, msgValue);
    }

    /// @notice Gets the time-weighted primary token balance for a given bptAmount
    /// @param poolContext pool context variables
    /// @param oracleContext oracle context variables
    /// @param bptAmount amount of balancer pool lp tokens
    /// @return primaryAmount primary token balance
    function _getTimeWeightedPrimaryBalance(
        Balancer2TokenPoolContext memory poolContext,
        StableOracleContext memory oracleContext,
        StrategyContext memory strategyContext,
        uint256 bptAmount
    ) internal view returns (uint256 primaryAmount) {
        uint256 oraclePairPrice = poolContext.basePool._getOraclePairPrice(strategyContext);

        // tokenIndex == 0 because _getOraclePairPrice always returns the price in terms of
        // the primary currency
        uint256 spotPrice = oracleContext._getSpotPrice({
            poolContext: poolContext,
            primaryBalance: poolContext.basePool.primaryBalance,
            secondaryBalance: poolContext.basePool.secondaryBalance,
            tokenIndex: 0
        });

        primaryAmount = poolContext.basePool._getTimeWeightedPrimaryBalance({
            strategyContext: strategyContext,
            poolClaim: bptAmount,
            oraclePrice: oraclePairPrice,
            spotPrice: spotPrice
        });
    }

    function _approveBalancerTokens(TwoTokenPoolContext memory poolContext, address bptSpender) internal {
        IERC20(poolContext.primaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
        IERC20(poolContext.secondaryToken).checkApprove(address(Deployments.BALANCER_VAULT), type(uint256).max);
        // Allow BPT spender to pull BALANCER_POOL_TOKEN
        poolContext.poolToken.checkApprove(bptSpender, type(uint256).max);
    }

    function _deposit(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 deposit,
        DepositParams memory params
    ) internal returns (uint256 strategyTokensMinted) {
        uint256 secondaryAmount;
        if (params.tradeData.length != 0) {
            // Allows users to trade on a different DEX instead of Balancer when joining
            (uint256 primarySold, uint256 secondaryBought) = poolContext.basePool._tradePrimaryForSecondary({
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
            minBPT: params.minPoolClaim
        });

        strategyTokensMinted = strategyContext._mintStrategyTokens(bptMinted);
    }

    function _redeem(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        AuraStakingContext memory stakingContext,
        uint256 strategyTokens,
        RedeemParams memory params
    ) internal returns (uint256 finalPrimaryBalance) {
        uint256 bptClaim = strategyContext._redeemStrategyTokens(strategyTokens);

        // Underlying token balances from exiting the pool
        (uint256 primaryBalance, uint256 secondaryBalance)
            = _unstakeAndExitPool(
                poolContext, stakingContext, bptClaim, params.minPrimary, params.minSecondary
            );

        finalPrimaryBalance = primaryBalance;
        if (secondaryBalance > 0) {
            uint256 primaryPurchased = poolContext.basePool._sellSecondaryBalance(
                strategyContext, params, secondaryBalance
            );

            finalPrimaryBalance += primaryPurchased;
        }
    }

    function _joinPoolAndStake(
        Balancer2TokenPoolContext memory poolContext,
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
            poolId: poolContext.poolId,
            poolToken: poolContext.basePool.poolToken,
            params: poolParams,
            minBPT: minBPT
        });

        // Check BPT threshold to make sure our share of the pool is
        // below maxPoolShare
        uint256 bptThreshold = strategyContext.vaultSettings._poolClaimThreshold(
            poolContext.basePool.poolToken.totalSupply()
        );
        uint256 bptHeldAfterJoin = strategyContext.vaultState.totalPoolClaim + bptMinted;
        if (bptHeldAfterJoin > bptThreshold)
            revert Errors.PoolShareTooHigh(bptHeldAfterJoin, bptThreshold);

        // Transfer token to Aura protocol for boosted staking
        bool success = stakingContext.booster.deposit(stakingContext.poolId, bptMinted, true); // stake = true
        if (!success) revert Errors.StakeFailed();
    }

    function _unstakeAndExitPool(
        Balancer2TokenPoolContext memory poolContext,
        AuraStakingContext memory stakingContext,
        uint256 bptClaim,
        uint256 minPrimary,
        uint256 minSecondary
    ) internal returns (uint256 primaryBalance, uint256 secondaryBalance) {
        // Withdraw BPT tokens back to the vault for redemption
        bool success = stakingContext.rewardPool.withdrawAndUnwrap(bptClaim, false); // claimRewards = false
        if (!success) revert Errors.UnstakeFailed();

        uint256[] memory exitBalances = BalancerUtils._exitPoolExactBPTIn({
            poolId: poolContext.poolId,
            poolToken: poolContext.basePool.poolToken,
            params: poolContext._getPoolParams(minPrimary, minSecondary, false), // isJoin = false
            bptExitAmount: bptClaim
        });
        
        (primaryBalance, secondaryBalance) 
            = (exitBalances[poolContext.basePool.primaryIndex], exitBalances[poolContext.basePool.secondaryIndex]);
    }

    /// @notice We value strategy tokens in terms of the primary balance. The time weighted
    /// primary balance is used in order to prevent pool manipulation.
    /// @param poolContext pool context variables
    /// @param strategyContext strategy context variables
    /// @param oracleContext oracle context variables
    /// @param strategyTokenAmount amount of strategy tokens
    /// @return underlyingValue underlying value of strategy tokens
    function _convertStrategyToUnderlying(
        Balancer2TokenPoolContext memory poolContext,
        StrategyContext memory strategyContext,
        StableOracleContext memory oracleContext,
        uint256 strategyTokenAmount
    ) internal view returns (int256 underlyingValue) {
        
        uint256 bptClaim 
            = strategyContext._convertStrategyTokensToPoolClaim(strategyTokenAmount);

        underlyingValue 
            = poolContext._getTimeWeightedPrimaryBalance(oracleContext, strategyContext, bptClaim).toInt();
    }
}