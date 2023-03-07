// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;
pragma abicoder v2;

import {Constants} from "../Constants.sol";

interface IUniswapMath {
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick);

    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96);

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount0, uint256 amount1);

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity);
}