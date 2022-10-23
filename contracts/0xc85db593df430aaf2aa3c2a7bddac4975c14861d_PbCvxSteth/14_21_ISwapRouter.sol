// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params)
        external
        returns (uint256 amountOut);
}