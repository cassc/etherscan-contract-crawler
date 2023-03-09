// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBunsDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}