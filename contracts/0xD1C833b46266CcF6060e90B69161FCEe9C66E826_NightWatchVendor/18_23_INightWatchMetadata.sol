// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Metadata contract interface of Night Watch
/// @author @YigitDuman
interface INightWatchMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}