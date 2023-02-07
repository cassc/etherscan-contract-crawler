// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @dev Data estructure to configure contract deposits.
struct DepositConfig {
    /// @dev Address of the ERC20 token used for deposits.
    address token;
    /// @dev Amount of tokens to deposit.
    uint256 amount;
    /// @dev Address recipient of the deposit.
    address recipient;
}