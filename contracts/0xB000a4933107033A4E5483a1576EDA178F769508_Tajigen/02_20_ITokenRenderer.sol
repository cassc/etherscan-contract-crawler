// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenRenderer {
    function tokenURI(uint256 tokenId, bytes32 soulHash) external view returns (string memory);
}