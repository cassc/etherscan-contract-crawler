// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface ITPirates {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}