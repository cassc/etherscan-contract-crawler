// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IETHButtonswapRouterErrors {
    /// @notice Only WETH contract can send ETH to contract
    error NonWETHSender();
    /// @notice WETH transfer failed
    error FailedWETHTransfer();
}