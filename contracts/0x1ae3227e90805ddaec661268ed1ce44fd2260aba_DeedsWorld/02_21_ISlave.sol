// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISlave {
    function masterMint(address mintTo, uint256 tokenId, uint8 usedBreeds) external ;
}