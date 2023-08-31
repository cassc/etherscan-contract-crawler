// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title Interface for WETH9
interface WETHInterface {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}