// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILeechStrategy {
    function deposit(
        address[] memory pathTokenInToToken0
    ) external returns (uint256);

    function withdrawAll() external;

    function withdraw(
        uint256 _amountLP,
        address[] memory token0toTokenOut,
        address[] memory token1toTokenOut
    ) external returns (uint256);
}