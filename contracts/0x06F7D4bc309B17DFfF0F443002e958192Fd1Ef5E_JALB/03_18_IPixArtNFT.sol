// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

/// @title IPixArtNFT
/// @notice Interface for the PixArtNFT contract
interface IPixArtNFT {

    /// @notice Build the NFT for a given token ID
    /// @param tokenId (uint256) ID of the token to query
    /// @return (string) base64 encoded metadata and SVG
    function composeTokenUri(uint256 tokenId) external view returns (string memory);
}