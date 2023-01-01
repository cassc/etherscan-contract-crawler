//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IBatcher.sol";

interface ITwoWayBatcher is IBatcher, IERC20 {
    /// @notice Event emitted on USDC deposit
    event Deposit(address indexed account, UFixed18 amount);
    /// @notice Event emitted on USDC withdraw
    event Withdraw(address indexed account, UFixed18 amount);

    /// @notice Error thrown on invalid USDC amount
    error TwoWayBatcherInvalidTokenAmount(UFixed18 amount);

    /// @notice Deposits USDC for Batcher to use in unwrapping flows
    function deposit(UFixed18 amount) external;

    /// @notice Withdraws USDC from Batcher
    function withdraw(UFixed18 amount) external;
}