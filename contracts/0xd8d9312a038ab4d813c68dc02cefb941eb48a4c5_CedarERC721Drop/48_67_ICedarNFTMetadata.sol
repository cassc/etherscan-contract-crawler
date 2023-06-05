// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICedarNFTMetadataV0 {
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) external returns (string memory);
}

interface ICedarNFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) view external returns (string memory);
}