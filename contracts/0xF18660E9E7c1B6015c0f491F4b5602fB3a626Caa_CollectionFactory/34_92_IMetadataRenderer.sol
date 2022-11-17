// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Used to interface with core of EditionsMetadataRenderer
 * @author Zora, [email protected]
 */
interface IMetadataRenderer {
    /**
     * @dev Store metadata for an edition
     * @param data Metadata
     */
    function initializeMetadata(bytes memory data) external;

    /**
     * @dev Get uri for token
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}