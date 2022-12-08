// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumKeyRing {
    function make(address to, uint256 id, uint256 amount) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}