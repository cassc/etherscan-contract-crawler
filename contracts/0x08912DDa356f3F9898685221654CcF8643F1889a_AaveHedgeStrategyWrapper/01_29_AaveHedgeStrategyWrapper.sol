// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./BaseHedgedStrategyWrapper.sol";
import "contracts/strategies/lending/BaseAaveStrategy.sol";
import "contracts/strategies/flashloan/BaseAaveFlashloanStrategy.sol";

/// @author YLDR <[email protected]>
contract AaveHedgeStrategyWrapper is BaseHedgedStrategyWrapper, BaseAaveStrategy, BaseAaveFlashloanStrategy {
    struct ConstructorParams {
        // BaseHedgedStrategyWrapper
        IERC4626Minimal strategy;
        uint256 initialLTV;
        ChainlinkPriceFeedAggregator pricesOracle;
        IAssetConverter assetConverter;
        // BaseLendingStrategy
        IERC20Metadata collateral;
        IERC20Metadata tokenToBorrow;
        // BaseAaveStrategy
        IAavePool aavePool;
        // ApyFlowVault
        IERC20Metadata asset;
        // ERC20
        string name;
        string symbol;
    }

    constructor(ConstructorParams memory params)
        BaseLendingStrategy(params.collateral, params.tokenToBorrow)
        BaseAaveStrategy(params.aavePool)
        BaseHedgedStrategyWrapper(params.strategy, params.initialLTV, params.pricesOracle, params.assetConverter)
        BaseAaveFlashloanStrategy(params.aavePool)
        ApyFlowVault(params.asset)
        ERC20(params.name, params.symbol)
    {}
}