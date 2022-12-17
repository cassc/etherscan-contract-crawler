// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {IStrategyVault} from "../../../interfaces/notional/IStrategyVault.sol";
import {VaultConfig} from "../../../interfaces/notional/IVaultController.sol";
import {IAuraBooster} from "../../../interfaces/aura/IAuraBooster.sol";
import {IAuraRewardPool} from "../../../interfaces/aura/IAuraRewardPool.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {ILiquidityGauge} from "../../../interfaces/balancer/ILiquidityGauge.sol";
import {IBalancerVault} from "../../../interfaces/balancer/IBalancerVault.sol";
import {IBalancerMinter} from "../../../interfaces/balancer/IBalancerMinter.sol";
import {IAsset} from "../../../interfaces/balancer/IBalancerVault.sol";
import {ITradingModule, Trade, TradeType} from "../../../interfaces/trading/ITradingModule.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

struct DeploymentParams {
    uint16 primaryBorrowCurrencyId;
    bytes32 balancerPoolId;
    ILiquidityGauge liquidityGauge;
    ITradingModule tradingModule;
    uint32 settlementPeriodInSeconds;
}

struct AuraVaultDeploymentParams {
    IAuraRewardPool auraRewardPool;
    DeploymentParams baseParams;
}

struct InitParams {
    string name;
    uint16 borrowCurrencyId;
    StrategyVaultSettings settings;
}

struct DepositParams {
    uint256 minBPT;
    bytes tradeData;
}

struct DepositTradeParams {
    uint256 tradeAmount;
    TradeParams tradeParams;
}

struct RedeemParams {
    uint256 minPrimary;
    uint256 minSecondary;
    bytes secondaryTradeParams;
}

/// @notice Parameters for trades
struct TradeParams {
    uint16 dexId;
    TradeType tradeType;
    uint256 oracleSlippagePercentOrLimit;
    bool tradeUnwrapped;
    bytes exchangeData;
}

/// @notice Parameters for joining/exiting Balancer pools
struct PoolParams {
    IAsset[] assets;
    uint256[] amounts;
    uint256 msgValue;
}

struct StableOracleContext {
    /// @notice Amplification parameter
    uint256 ampParam;
}

struct BoostedOracleContext {
    /// @notice Amplification parameter
    uint256 ampParam;
    /// @notice BPT balance in the pool
    uint256 bptBalance;
    /// @notice Protocol fee amount used to calculate the virtual supply
    uint256 dueProtocolFeeBptAmount;
}

/// @notice Balancer pool related fields
struct PoolContext {
    IERC20 pool;
    bytes32 poolId;
}

struct AuraStakingContext {
    ILiquidityGauge liquidityGauge;
    IAuraBooster auraBooster;
    IAuraRewardPool auraRewardPool;
    uint256 auraPoolId;
    IERC20[] rewardTokens;
}

struct TwoTokenPoolContext {
    address primaryToken;
    address secondaryToken;
    uint8 primaryIndex;
    uint8 secondaryIndex;
    uint8 primaryDecimals;
    uint8 secondaryDecimals;
    uint256 primaryBalance;
    uint256 secondaryBalance;
    uint256 primaryScaleFactor;
    uint256 secondaryScaleFactor;
    PoolContext basePool;
}

struct ThreeTokenPoolContext {
    address tertiaryToken;
    uint8 tertiaryIndex;
    uint8 tertiaryDecimals;
    uint256 tertiaryBalance;
    TwoTokenPoolContext basePool;
}

struct StrategyContext {
    uint32 settlementPeriodInSeconds;
    ITradingModule tradingModule;
    StrategyVaultSettings vaultSettings;
    StrategyVaultState vaultState;
}

struct MetaStable2TokenAuraStrategyContext {
    TwoTokenPoolContext poolContext;
    StableOracleContext oracleContext;
    AuraStakingContext stakingContext;
    StrategyContext baseStrategy;
}

struct Boosted3TokenAuraStrategyContext {
    ThreeTokenPoolContext poolContext;
    BoostedOracleContext oracleContext;
    AuraStakingContext stakingContext;
    StrategyContext baseStrategy;
}

struct NormalSettlementData {
    uint256 maxUnderlyingSurplus;
    uint256 redeemStrategyTokenAmount;
    int256 underlyingCashRequiredToSettle;
}

struct BoostedSettlementData {
    uint256 maxUnderlyingSurplus;
    uint256 primarySettlementBalance;
    uint256 redeemStrategyTokenAmount;
    int256 underlyingCashRequiredToSettle;
}

struct Balanced2TokenRewardTradeParams {
    SingleSidedRewardTradeParams primaryTrade;
    SingleSidedRewardTradeParams secondaryTrade;
}

struct SingleSidedRewardTradeParams {
    address sellToken;
    address buyToken;
    uint256 amount;
    TradeParams tradeParams;
}

struct ReinvestRewardParams {
    bytes tradeData;
    uint256 minBPT;
}

struct StrategyVaultSettings {
    uint256 maxUnderlyingSurplus;
    /// @notice Slippage limit for normal settlement
    uint32 settlementSlippageLimitPercent;
    /// @notice Slippage limit for post maturity settlement
    uint32 postMaturitySettlementSlippageLimitPercent;
    /// @notice Slippage limit for emergency settlement (vault owns too much of the Balancer pool)
    uint32 emergencySettlementSlippageLimitPercent;
    /// @notice Slippage limit for selling reward tokens
    uint32 maxRewardTradeSlippageLimitPercent;
    uint16 maxBalancerPoolShare;
    /// @notice Cool down in minutes for normal settlement
    uint16 settlementCoolDownInMinutes;
    /// @notice Limits the amount of allowable deviation from the oracle price
    uint16 oraclePriceDeviationLimitPercent;
    /// @notice Slippage limit for joining/exiting Balancer pools
    uint16 balancerPoolSlippageLimitPercent;
}

struct StrategyVaultState {
    uint256 totalBPTHeld;
    /// @notice Total number of strategy tokens across all maturities
    uint80 totalStrategyTokenGlobal;
    uint32 lastSettlementTimestamp;
}