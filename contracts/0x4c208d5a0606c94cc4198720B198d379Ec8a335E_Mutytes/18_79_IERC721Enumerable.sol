// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 enumerable extension interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable {
    /**
     * @notice Get the total token supply
     * @return supply The total supply amount
     */
    function totalSupply() external returns (uint256);

    /**
     * @notice Get a token by global enumeration index
     * @param index The token position
     * @return tokenId The token id
     */
    function tokenByIndex(uint256 index) external returns (uint256);

    /**
     * @notice Get an owner's token by enumeration index
     * @param owner The owner's address
     * @param index The token position
     * @return tokenId The token id
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
}