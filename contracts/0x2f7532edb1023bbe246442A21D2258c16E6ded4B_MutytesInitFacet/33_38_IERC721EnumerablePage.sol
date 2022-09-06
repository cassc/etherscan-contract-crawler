// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 enumerable page interface
 */
interface IERC721EnumerablePage {
    /**
     * @notice Get a token by enumeration index
     * @param index The token position
     * @return tokenId The token id
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}