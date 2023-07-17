// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { IRouterComponent } from "./IRouterComponent.sol";

import { StrategyPathTask } from "../data/StrategyPathTask.sol";

interface IPathResolver is IRouterComponent {
    function findOneTokenPath(
        uint8 typeIn,
        address tokenIn,
        uint256 amount,
        StrategyPathTask memory task
    ) external returns (StrategyPathTask memory);

    function findOpenStrategyPath(StrategyPathTask memory task)
        external
        returns (StrategyPathTask memory);
}