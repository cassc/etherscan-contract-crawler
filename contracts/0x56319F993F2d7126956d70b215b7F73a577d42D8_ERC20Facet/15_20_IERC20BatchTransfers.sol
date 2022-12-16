// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Batch Transfers.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0xc05327e6.
interface IERC20BatchTransfers {
    /// @notice Transfers multiple amounts of tokens to multiple recipients from the sender.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if the sender does not have at least `sum(values)` of balance.
    /// @dev Emits an {IERC20-Transfer} event for each transfer.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    /// @return result Whether the operation succeeded.
    function batchTransfer(address[] calldata recipients, uint256[] calldata values) external returns (bool result);

    /// @notice Transfers multiple amounts of tokens to multiple recipients from a specified address.
    /// @dev Reverts if `recipients` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if `from` does not have at least `sum(values)` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `sum(values)` of allowance by `from`.
    /// @dev Emits an {IERC20-Transfer} event for each transfer.
    /// @dev Optionally emits an {IERC20-Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to be transferred.
    /// @param recipients The list of accounts to transfer the tokens to.
    /// @param values The list of amounts of tokens to transfer to each of `recipients`.
    /// @return result Whether the operation succeeded.
    function batchTransferFrom(address from, address[] calldata recipients, uint256[] calldata values) external returns (bool result);
}