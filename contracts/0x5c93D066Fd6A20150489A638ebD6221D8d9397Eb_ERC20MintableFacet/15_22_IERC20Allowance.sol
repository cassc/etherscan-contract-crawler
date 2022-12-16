// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Allowance.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x9d075186.
interface IERC20Allowance {
    /// @notice Increases the allowance granted to an account by the sender.
    /// @notice This is an alternative to {approve} that can be used as a mitigation for transaction ordering problems.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender`'s allowance by the sender overflows.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by the sender.
    /// @param spender The account whose allowance is being increased.
    /// @param value The allowance amount increase.
    /// @return result Whether the operation succeeded.
    function increaseAllowance(address spender, uint256 value) external returns (bool result);

    /// @notice Decreases the allowance granted to an account by the sender.
    /// @notice This is an alternative to {approve} that can be used as a mitigation for transaction ordering problems.
    /// @dev Reverts if `spender` is the zero address.
    /// @dev Reverts if `spender` does not have at least `value` of allowance by the sender.
    /// @dev Emits an {IERC20-Approval} event with an updated allowance for `spender` by the sender.
    /// @param spender The account whose allowance is being decreased.
    /// @param value The allowance amount decrease.
    /// @return result Whether the operation succeeded.
    function decreaseAllowance(address spender, uint256 value) external returns (bool result);
}