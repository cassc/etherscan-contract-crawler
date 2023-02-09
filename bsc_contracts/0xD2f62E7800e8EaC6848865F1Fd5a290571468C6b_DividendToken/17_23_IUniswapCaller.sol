// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapCaller {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external;
}