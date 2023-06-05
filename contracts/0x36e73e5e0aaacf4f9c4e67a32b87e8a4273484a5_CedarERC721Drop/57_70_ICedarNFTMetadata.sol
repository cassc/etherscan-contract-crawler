// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// TODO: unify with ICedarSFTMetadata into ICedarTokenMetadata
interface ICedarNFTMetadataV1 {
    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}