// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x5190c92c.
interface IERC1155Mintable {
    /// @notice Safely mints some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(address to, uint256 id, uint256 value, bytes calldata data) external;

    /// @notice Safely mints a batch of tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
}