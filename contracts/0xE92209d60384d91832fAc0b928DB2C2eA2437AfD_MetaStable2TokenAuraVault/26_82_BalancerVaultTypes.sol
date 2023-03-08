// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {
    StrategyContext, 
    StrategyVaultSettings, 
    TradeParams,
    TwoTokenPoolContext,
    ThreeTokenPoolContext
} from "../common/VaultTypes.sol";
import {IStrategyVault} from "../../../interfaces/notional/IStrategyVault.sol";
import {VaultConfig} from "../../../interfaces/notional/IVaultController.sol";
import {IAuraBooster} from "../../../interfaces/aura/IAuraBooster.sol";
import {IAuraRewardPool} from "../../../interfaces/aura/IAuraRewardPool.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {ILiquidityGauge} from "../../../interfaces/balancer/ILiquidityGauge.sol";
import {IBalancerVault} from "../../../interfaces/balancer/IBalancerVault.sol";
import {IBalancerMinter} from "../../../interfaces/balancer/IBalancerMinter.sol";
import {ITradingModule, Trade, TradeType} from "../../../interfaces/trading/ITradingModule.sol";
import {IAsset} from "../../../interfaces/balancer/IBalancerVault.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

struct DeploymentParams {
    uint16 primaryBorrowCurrencyId;
    bytes32 balancerPoolId;
    ILiquidityGauge liquidityGauge;
    ITradingModule tradingModule;
    uint32 settlementPeriodInSeconds;
}

struct AuraVaultDeploymentParams {
    IAuraRewardPool rewardPool;
    DeploymentParams baseParams;
}

struct InitParams {
    string name;
    uint16 borrowCurrencyId;
    StrategyVaultSettings settings;
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

struct UnderlyingPoolContext {
    uint256 mainScaleFactor;
    uint256 mainBalance;
    uint256 wrappedScaleFactor;
    uint256 wrappedBalance;
    uint256 virtualSupply;
    uint256 fee;
    uint256 lowerTarget;
    uint256 upperTarget;
}

struct BoostedOracleContext {
    /// @notice Amplification parameter
    uint256 ampParam;
    /// @notice BPT balance in the pool
    uint256 bptBalance;
    /// @notice Boosted pool swap fee
    uint256 swapFeePercentage;
    /// @notice Virtual supply
    uint256 virtualSupply;
    /// @notice Underlying linear pool for the primary token
    UnderlyingPoolContext[] underlyingPools;
}

struct AuraStakingContext {
    ILiquidityGauge liquidityGauge;
    IAuraBooster booster;
    IAuraRewardPool rewardPool;
    uint256 poolId;
    IERC20[] rewardTokens;
}

struct Balancer2TokenPoolContext {
    TwoTokenPoolContext basePool;
    uint256 primaryScaleFactor;
    uint256 secondaryScaleFactor;
    bytes32 poolId;
}

struct Balancer3TokenPoolContext {
    ThreeTokenPoolContext basePool;
    uint256 primaryScaleFactor;
    uint256 secondaryScaleFactor;
    uint256 tertiaryScaleFactor;
    bytes32 poolId;
}

struct MetaStable2TokenAuraStrategyContext {
    Balancer2TokenPoolContext poolContext;
    StableOracleContext oracleContext;
    AuraStakingContext stakingContext;
    StrategyContext baseStrategy;
}

struct Boosted3TokenAuraStrategyContext {
    Balancer3TokenPoolContext poolContext;
    BoostedOracleContext oracleContext;
    AuraStakingContext stakingContext;
    StrategyContext baseStrategy;
}