// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMetadataResolver {
    /// @notice Metadata URI for the given token ID.
    /// @param tokenId uint256 token ID.
    /// @return Metadata URI string.
    function uri(uint256 tokenId) external view returns (string memory);
}