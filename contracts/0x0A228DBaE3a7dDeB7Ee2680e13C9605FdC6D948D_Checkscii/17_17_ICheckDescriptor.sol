// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ICheckDescriptor {
    function tokenURI(string memory tokenId, string memory seed) external view returns (string memory);
}