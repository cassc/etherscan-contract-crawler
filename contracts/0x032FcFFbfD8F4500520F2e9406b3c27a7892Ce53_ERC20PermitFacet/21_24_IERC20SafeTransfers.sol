// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, optional extension: Safe Transfers.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x53f41a97.
interface IERC20SafeTransfers {
    /// @notice Transfers an amount of tokens to a recipient from the sender. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender does not have at least `value` of balance.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received` fails, reverts or is rejected.
    /// @dev Emits an {IERC20-Transfer} event.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    /// @return result Whether the operation succeeded.
    function safeTransfer(address to, uint256 value, bytes calldata data) external returns (bool result);

    /// @notice Transfers an amount of tokens to a recipient from a specified address. If the recipient is a contract, calls `onERC20Received` on it.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` does not have at least `value` of balance.
    /// @dev Reverts if the sender is not `from` and does not have at least `value` of allowance by `from`.
    /// @dev Reverts if `to` is a contract and the call to `onERC20Received(address,address,uint256,bytes)` fails, reverts or is rejected.
    /// @dev Emits an {IERC20-Transfer} event.
    /// @dev Optionally emits an {IERC20-Approval} event if the sender is not `from` (non-standard).
    /// @param from The account which owns the tokens to transfer.
    /// @param to The account to transfer the tokens to.
    /// @param value The amount of tokens to transfer.
    /// @param data Optional additional data with no specified format, to be passed to the receiver contract.
    /// @return result Whether the operation succeeded.
    function safeTransferFrom(address from, address to, uint256 value, bytes calldata data) external returns (bool result);
}