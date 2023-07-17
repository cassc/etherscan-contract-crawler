// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IDNAManager {
   function setDNA(uint256 tokenId, uint256 dna) external;
   function dnas(uint256 tokenId) external view returns(uint256);
}