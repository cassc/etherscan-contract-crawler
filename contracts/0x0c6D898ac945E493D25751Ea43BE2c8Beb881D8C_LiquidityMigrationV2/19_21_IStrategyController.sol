//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IStrategy.sol";
import "./IStrategyRouter.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";
import "../helpers/StrategyTypes.sol";

interface IStrategyController is StrategyTypes {
    function setupStrategy(
        address manager_,
        address strategy_,
        InitialState memory state_,
        address router_,
        bytes memory data_
    ) external payable;

    function deposit(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external payable;

    function withdrawETH(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external;

    function withdrawWETH(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external;

    function rebalance(
        IStrategy strategy,
        IStrategyRouter router,
        bytes memory data
    ) external;

    function restructure(
        IStrategy strategy,
        StrategyItem[] memory strategyItems
    ) external;

    function finalizeStructure(
        IStrategy strategy,
        IStrategyRouter router,
        bytes memory data
    ) external;

    function updateValue(
        IStrategy strategy,
        TimelockCategory category,
        uint256 newValue
    ) external;

    function finalizeValue(address strategy) external;

    function openStrategy(IStrategy strategy) external;

    function setStrategy(IStrategy strategy) external;

    function initialized(address strategy) external view returns (bool);

    function strategyState(address strategy) external view returns (StrategyState memory);

    function verifyStructure(address strategy, StrategyItem[] memory newItems)
        external
        view
        returns (bool);

    function oracle() external view returns (IOracle);

    function whitelist() external view returns (IWhitelist);
}