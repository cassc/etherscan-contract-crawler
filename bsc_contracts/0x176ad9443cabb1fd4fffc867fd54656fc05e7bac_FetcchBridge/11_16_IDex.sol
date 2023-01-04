//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDex {
    event NativeFundsSwapped(
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event ERC20FundsSwapped(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    );

    function swapNative(address _tokenOut, address _receiver)
        external
        payable
        returns (uint256 amountOut);

    function swapERC20(
        address _tokenIn,
        address _tokenOut,
        uint256 amountIn,
        address _receiver
    ) external returns (uint256 amountOut);
}