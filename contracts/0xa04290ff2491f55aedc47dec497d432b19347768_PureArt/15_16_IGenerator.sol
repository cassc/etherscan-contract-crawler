// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGenerator {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}