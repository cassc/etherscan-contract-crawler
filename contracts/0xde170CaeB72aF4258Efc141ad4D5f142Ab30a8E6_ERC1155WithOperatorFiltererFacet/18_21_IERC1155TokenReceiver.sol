// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, Tokens Receiver.
/// @notice Interface for any contract that wants to support transfers from ERC1155 asset contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
interface IERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC1155 token type.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
    /// @dev Return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (`0xf23a6e61`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param id The ID of the token being transferred
    /// @param value The amount of tokens being transferred
    /// @param data Additional data with no specified format
    /// @return magicValue `0xf23a6e61` to accept the transfer, or any other value to reject it.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4 magicValue);

    /// @notice Handles the receipt of multiple ERC1155 token types.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
    /// @dev Return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (`0xbc197c81`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the batch transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param ids An array containing ids of each token being transferred (order and length must match _values array)
    /// @param values An array containing amounts of each token being transferred (order and length must match _ids array)
    /// @param data Additional data with no specified format
    /// @return magicValue `0xbc197c81` to accept the transfer, or any other value to reject it.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4 magicValue);
}