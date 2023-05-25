// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITokenRenderer {
    function getTokenURI(uint256 tokenId, string memory name) external view returns (string memory);
}