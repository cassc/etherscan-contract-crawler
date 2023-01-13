// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../ISBT.sol";

/**
 * @title SBT Soulbound Token Standard, optional metadata extension
 */
interface ISBTMetadata is ISBT {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}