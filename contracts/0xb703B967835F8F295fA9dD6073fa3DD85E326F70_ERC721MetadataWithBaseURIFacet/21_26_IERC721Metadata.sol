// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Metadata.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata {
    /// @notice Gets the name of the token. E.g. "My Token".
    /// @return tokenName The name of the token.
    function name() external view returns (string memory tokenName);

    /// @notice Gets the symbol of the token. E.g. "TOK".
    /// @return tokenSymbol The symbol of the token.
    function symbol() external view returns (string memory tokenSymbol);

    /// @notice Gets the metadata URI for a token identifier.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier.
    /// @return uri The metadata URI for the token identifier.
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
}