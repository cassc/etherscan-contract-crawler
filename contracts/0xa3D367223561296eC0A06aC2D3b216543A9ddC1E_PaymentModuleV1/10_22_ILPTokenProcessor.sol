// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ILPTokenProcessor {
    function addLiquidityPoolToken(address tokenAddress) external;

    function getRouter(address lpTokenAddress) external view returns (address);

    function isLiquidityPoolToken(address tokenAddress) external view returns (bool);
}