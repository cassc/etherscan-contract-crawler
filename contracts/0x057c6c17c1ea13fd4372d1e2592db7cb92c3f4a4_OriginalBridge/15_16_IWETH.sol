// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IWETH {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint) external;
}