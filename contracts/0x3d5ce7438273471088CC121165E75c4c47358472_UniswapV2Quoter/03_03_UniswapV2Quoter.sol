// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract UniswapV2Quoter {
    /// @notice Quotes amountIn for exactOut swap through UniswapV2-like protocol
    /// @param router Address of the router to use
    /// @param amountOut Required amount out
    /// @param path Path used for swap
    function quoteExactOut(
        address router,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256) {
        return IUniswapV2Router02(router).getAmountsIn(amountOut, path)[0];
    }
}