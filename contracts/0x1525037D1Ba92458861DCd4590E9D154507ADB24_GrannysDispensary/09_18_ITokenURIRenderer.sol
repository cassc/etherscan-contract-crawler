// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenURIRenderer {
    function tokenURI(uint256 tokenId, string memory baseURI) external view returns (string memory);
}