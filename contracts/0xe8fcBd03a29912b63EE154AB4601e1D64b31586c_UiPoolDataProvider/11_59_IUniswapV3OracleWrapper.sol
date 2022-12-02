// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IAtomicPriceAggregator} from "../interfaces/IAtomicPriceAggregator.sol";
import {IUniswapV3PositionInfoProvider} from "../interfaces/IUniswapV3PositionInfoProvider.sol";

interface IUniswapV3OracleWrapper is
    IAtomicPriceAggregator,
    IUniswapV3PositionInfoProvider
{}