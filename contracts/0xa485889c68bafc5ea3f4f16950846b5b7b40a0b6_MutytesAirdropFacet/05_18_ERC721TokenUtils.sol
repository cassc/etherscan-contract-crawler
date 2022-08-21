// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token utilities
 */
library ERC721TokenUtils {
    uint256 constant HOLDER_OFFSET = 8;
    uint256 constant INDEX_BITMASK = (1 << HOLDER_OFFSET) - 1; // = 0xFF

    function toTokenId(address owner) internal pure returns (uint256) {
        return uint256(uint160(owner)) << HOLDER_OFFSET;
    }

    function index(uint256 tokenId) internal pure returns (uint256) {
        return tokenId & INDEX_BITMASK;
    }

    function holder(uint256 tokenId) internal pure returns (address) {
        return address(uint160(tokenId >> HOLDER_OFFSET));
    }
}