// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice Used to interface with core of EditionsMetadataRenderer
 * @author Zora, [email protected]
 */
interface IMetadataRenderer {
    /**
     * @notice Store metadata for an edition
     * @param data Metadata
     */
    function initializeMetadata(bytes memory data) external;

    /**
     * @notice Get uri for token
     * @param tokenId ID of token to get uri for
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}