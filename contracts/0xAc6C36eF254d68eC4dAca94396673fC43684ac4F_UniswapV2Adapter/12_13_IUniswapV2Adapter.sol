// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";

interface IUniswapV2Adapter {
    function router() external view returns (IUniswapV2Router02);

    function swap(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
    ) external payable returns (uint256 _amountOut);

    function calculateMaxAmountIn(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB
    ) external view returns (bool aToB, uint256 amountIn);
}