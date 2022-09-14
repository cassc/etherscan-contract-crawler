// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract CreatorTracking {
    mapping(uint256 => address) private creators;

    function setCreator(uint256 tokenId, address c) internal {
        creators[tokenId] = c;
    }

    function getCreator(uint256 tokenId) public view returns (address) {
        return creators[tokenId];
    }
}