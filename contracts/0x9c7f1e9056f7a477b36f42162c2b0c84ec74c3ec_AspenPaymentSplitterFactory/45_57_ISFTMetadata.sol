// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarSFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) external view returns (string memory);
}

interface IAspenSFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) external view returns (string memory);
}