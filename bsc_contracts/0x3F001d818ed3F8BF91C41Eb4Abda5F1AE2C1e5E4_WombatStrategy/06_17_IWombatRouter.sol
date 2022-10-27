// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IWombatRouter {
    function swapExactTokensForNative(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}