// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/BID721/extensions/IBID721Metadata.sol)

pragma solidity ^0.8.9;

import "../IBID721.sol";

/**
 * @title BID-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IBID721Metadata is IBID721 {
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