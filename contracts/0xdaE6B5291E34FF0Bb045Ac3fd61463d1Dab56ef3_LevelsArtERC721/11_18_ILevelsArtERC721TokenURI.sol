// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev Interface of LevelsArtERC721TokenURI
 */
interface ILevelsArtERC721TokenURI {
    /**
     * @dev Used to return the token's URI
     */
    function tokenURI(uint256 tokenId) external pure returns (string memory);

    /**
     * @dev Used to return the token's URI
     */
    function tokenURI(
        uint256 tokenId,
        uint256 seed
    ) external pure returns (string memory);
}