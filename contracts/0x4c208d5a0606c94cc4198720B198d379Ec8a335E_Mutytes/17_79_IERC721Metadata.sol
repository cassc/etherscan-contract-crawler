// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 metadata extension interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata {
    /**
     * @notice Get the token name
     * @return name The token name
     */
    function name() external returns (string memory);

    /**
     * @notice Get the token symbol
     * @return symbol The token symbol
     */
    function symbol() external returns (string memory);

    /**
     * @notice Get the URI of a token
     * @param tokenId The token id
     * @return tokenURI The token URI
     */
    function tokenURI(uint256 tokenId) external returns (string memory);
}