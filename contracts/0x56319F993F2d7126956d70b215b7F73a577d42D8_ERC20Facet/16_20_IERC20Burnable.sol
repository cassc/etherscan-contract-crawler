// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x3b5a0bf8.
interface IERC20Burnable {
    /// @notice Burns an amount of tokens from the sender, decreasing the total supply.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Emits an {IERC20-Transfer} event with `to` set to the zero address.
    /// @param value The amount of tokens to burn.
    /// @return result Whether the operation succeeded.
    function burn(uint256 value) external returns (bool result);

    /// @notice Burns an amount of tokens from a specified address, decreasing the total supply.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Emits an {IERC20-Transfer} event with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event if the sender is not `from` (non-standard).
    /// @param from The account to burn the tokens from.
    /// @param value The amount of tokens to burn.
    /// @return result Whether the operation succeeded.
    function burnFrom(address from, uint256 value) external returns (bool result);

    /// @notice Burns multiple amounts of tokens from multiple owners, decreasing the total supply.
    /// @dev Reverts if `owners` and `values` have different lengths.
    /// @dev Reverts if an `owner` does not have at least the corresponding `value` of balance.
    /// @dev Reverts if the sender is not an `owner` and does not have at least the corresponding `value` of allowance by this `owner`.
    /// @dev Emits an {IERC20-Transfer} event for each transfer with `to` set to the zero address.
    /// @dev Optionally emits an {Approval} event for each transfer if the sender is not this `owner` (non-standard).
    /// @param owners The list of accounts to burn the tokens from.
    /// @param values The list of amounts of tokens to burn.
    /// @return result Whether the operation succeeded.
    function batchBurnFrom(address[] calldata owners, uint256[] calldata values) external returns (bool result);
}