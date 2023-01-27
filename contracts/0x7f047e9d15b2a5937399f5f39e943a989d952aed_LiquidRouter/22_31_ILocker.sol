// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ILocker {
    /// @notice Deposit & Lock Token
    /// @dev User needs to approve the contract to transfer the token
    /// @param amount The amount of token to deposit
    /// @param lock Whether to lock the token
    /// @param stake Whether to stake the token
    /// @param recipient User to deposit for
    function deposit(uint256 amount, bool lock, bool stake, address recipient) external;

    /// @notice Deposits all the token of a recipient & locks them based on the options choosen
    /// @dev User needs to approve the contract to transfer Token tokens
    /// @param lock Whether to lock the token
    /// @param stake Whether to stake the token
    /// @param recipient User to deposit for
    function depositAll(bool lock, bool stake, address recipient) external;
}