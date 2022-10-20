// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}