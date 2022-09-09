// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICedarSFTMetadataV0 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) external returns (string memory);
}

interface ICedarSFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) view external returns (string memory);
}