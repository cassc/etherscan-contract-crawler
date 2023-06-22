// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;


/// @title Interface for WETH9
interface IWETH9 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}