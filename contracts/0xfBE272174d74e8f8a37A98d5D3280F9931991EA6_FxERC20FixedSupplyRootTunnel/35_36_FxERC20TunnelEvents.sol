// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

abstract contract FxERC20TunnelEvents {
    /// @notice Emitted when an ERC20 token has been mapped.
    /// @param rootToken The root ERC20 token.
    /// @param childToken The child ERC20 token.
    event FxERC20TokenMapping(address indexed rootToken, address indexed childToken);

    /// @notice Emitted when some ERC20 token has been withdrawn.
    /// @param rootToken The root ERC20 token.
    /// @param childToken The child ERC20 token.
    /// @param withdrawer The withdrawer address.
    /// @param recipient The recipient address.
    /// @param amount The withdrawal amount.
    event FxERC20Withdrawal(address indexed rootToken, address indexed childToken, address withdrawer, address recipient, uint256 amount);

    /// @notice Emitted when some ERC20 token has been deposited.
    /// @param rootToken The root ERC20 token.
    /// @param childToken The child ERC20 token.
    /// @param depositor The depositor address.
    /// @param recipient The recipient address.
    /// @param amount The deposit amount.
    event FxERC20Deposit(address indexed rootToken, address indexed childToken, address depositor, address recipient, uint256 amount);
}