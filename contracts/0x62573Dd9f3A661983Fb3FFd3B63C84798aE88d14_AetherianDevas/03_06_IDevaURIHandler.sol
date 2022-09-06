// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IDevaURIHandler {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}