// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


interface IProof {
    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
}