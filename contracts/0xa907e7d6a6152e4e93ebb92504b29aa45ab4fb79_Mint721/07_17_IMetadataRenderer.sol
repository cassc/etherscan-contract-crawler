// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMetadataRenderer {
    /// @notice Retrieves the token URI for the specified token ID.
    /// @param tokenId The ID of the token.
    /// @return uri The URI of the token.
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
}