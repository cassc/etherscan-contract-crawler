// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice Dawn of Insrt token collection interface
 */
interface IDawnOfInsrt {
    /**
     * @notice returns tier of given token
     * @param tokenId id of token to check
     * @return tier tier of tokenId
     */
    function tokenTier(uint256 tokenId) external view returns (uint8 tier);
}