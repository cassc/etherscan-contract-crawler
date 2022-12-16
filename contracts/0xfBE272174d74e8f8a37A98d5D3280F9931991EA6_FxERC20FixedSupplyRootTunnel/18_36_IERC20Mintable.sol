// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x28963e1e.
interface IERC20Mintable {
    /// @notice Mints an amount of tokens to a recipient, increasing the total supply.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits an {IERC20-Transfer} event with `from` set to the zero address.
    /// @param to The account to mint the tokens to.
    /// @param value The amount of tokens to mint.
    function mint(address to, uint256 value) external;

    /// @notice Mints multiple amounts of tokens to multiple recipients, increasing the total supply.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the total supply overflows.
    /// @dev Emits an {IERC20-Transfer} event for each transfer with `from` set to the zero address.
    /// @param recipients The list of accounts to mint the tokens to.
    /// @param values The list of amounts of tokens to mint to each of `recipients`.
    function batchMint(address[] calldata recipients, uint256[] calldata values) external;
}