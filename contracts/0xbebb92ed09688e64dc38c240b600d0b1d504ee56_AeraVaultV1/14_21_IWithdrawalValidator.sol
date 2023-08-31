// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/// @title Withdrawal validation logic.
/// @notice Represents the withdrawal conditions for a vault.
/// @dev Should be extended by vault owner or guardian, deployed and attached
///      to a vault instance. Withdrawal validator needs to respond to
///      shortfall conditions and provide an accurate allowance.
interface IWithdrawalValidator {
    /// @notice Determine how much of each token could be withdrawn under
    ///         current conditions.
    /// @return token0Amount, token1Amount The quantity of each token that
    ///         can be withdrawn from the vault.
    /// @dev Token quantity value should be interpreted with the same
    ///      decimals as the token ERC20 balance.
    function allowance() external returns (uint256[] memory);
}