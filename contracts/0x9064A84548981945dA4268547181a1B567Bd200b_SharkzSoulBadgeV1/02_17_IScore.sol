// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * IScore interface
 *******************************************************************************
 * Creator: Sharkz Entertainment
 * Author: Jason Hoi
 *
 */

pragma solidity ^0.8.7;

/**
 * @dev Interface of token score, external token contract may accumulate total 
 * score from multiple IScore tokens.
 */
interface IScore {
    /**
     * @dev Get base score for each token (this is the unit score for different
     *  `tokenId` or owner address)
     */
    function baseScore() external view returns (uint256);

    /**
     * @dev Get score for individual `tokenId`
     * This function is needed only when score varies between token ids.
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByToken(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Get score of an address
     * In order to accumulate score, try to avoid any revert() if user submitted 
     * non-existent token id or owner address.
     *
     */
    function scoreByAddress(address addr) external view returns (uint256);
}