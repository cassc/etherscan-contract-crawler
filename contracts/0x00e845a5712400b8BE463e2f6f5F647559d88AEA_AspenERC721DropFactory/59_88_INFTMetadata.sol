// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ICedarNFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IAspenNFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}