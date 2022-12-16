// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x8e773e13.
interface IERC721Mintable {
    /// @notice Unsafely mints a token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mint(address to, uint256 tokenId) external;

    /// @notice Safely mints a token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC721-Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMint(address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Unsafely mints a batch of tokens.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMint(address to, uint256[] calldata tokenIds) external;
}