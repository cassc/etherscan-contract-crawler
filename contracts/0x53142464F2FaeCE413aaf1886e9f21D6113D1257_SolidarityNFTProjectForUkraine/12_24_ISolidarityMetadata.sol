// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title ISolidarityMetadata
 * @author @NiftyMike, NFT Culture
 * @dev Super thin interface definition for onchain metadata for Solidarity.
 */
interface ISolidarityMetadata {
    function getAsString(uint256 tokenId, uint256 tokenType) external view returns (string memory);

    function getAsEncodedString(uint256 tokenId, uint256 tokenType)
        external
        view
        returns (string memory);
}