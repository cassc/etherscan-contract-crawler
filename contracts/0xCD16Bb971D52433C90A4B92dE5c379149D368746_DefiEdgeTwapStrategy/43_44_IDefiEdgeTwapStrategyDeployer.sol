// SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../interfaces/IOneInchRouter.sol";
import "./ITwapStrategyFactory.sol";
import "./ITwapStrategyManager.sol";
import "./ITwapStrategyBase.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@chainlink/contracts/src/v0.7/interfaces/FeedRegistryInterface.sol";

interface IDefiEdgeTwapStrategyDeployer {
    function createStrategy(
        ITwapStrategyFactory _factory,
        IUniswapV3Pool _pool,
        IOneInchRouter _swapRouter,
        FeedRegistryInterface _chainlinkRegistry,
        ITwapStrategyManager _manager,
        bool[2] memory _useTwap,
        ITwapStrategyBase.Tick[] memory _ticks
    ) external returns (address);

    event StrategyDeployed(address strategy);
}