// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x921ed8d1.
interface IERC1155Burnable {
    /// @notice Burns some token.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(address from, uint256 id, uint256 value) external;

    /// @notice Burns multiple tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(address from, uint256[] calldata ids, uint256[] calldata values) external;
}