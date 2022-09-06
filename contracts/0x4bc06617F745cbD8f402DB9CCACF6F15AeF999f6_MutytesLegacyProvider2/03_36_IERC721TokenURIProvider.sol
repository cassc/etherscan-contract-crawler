// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token URI provider interface
 */
interface IERC721TokenURIProvider {
    /**
     * @notice Get the URI of a token
     * @param tokenId The token id
     * @return tokenURI The token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}