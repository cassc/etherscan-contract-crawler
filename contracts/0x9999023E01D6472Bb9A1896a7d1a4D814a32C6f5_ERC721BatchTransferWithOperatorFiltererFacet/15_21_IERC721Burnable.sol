// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x8b8b4ef5.
interface IERC721Burnable {
    /// @notice Burns a token.
    /// @dev Reverts if `tokenId` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits an {IERC721-Transfer} event with `to` set to the zero address.
    /// @param from The current token owner.
    /// @param tokenId The identifier of the token to burn.
    function burnFrom(address from, uint256 tokenId) external;

    /// @notice Burns a batch of tokens.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits an {IERC721-Transfer} event with `to` set to the zero address for each of `tokenIds`.
    /// @param from The current tokens owner.
    /// @param tokenIds The identifiers of the tokens to burn.
    function batchBurnFrom(address from, uint256[] calldata tokenIds) external;
}