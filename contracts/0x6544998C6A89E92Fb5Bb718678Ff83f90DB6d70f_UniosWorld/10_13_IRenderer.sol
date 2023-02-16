// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}