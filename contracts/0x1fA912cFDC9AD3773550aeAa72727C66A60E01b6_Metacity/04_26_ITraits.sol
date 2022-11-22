// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.13;

interface ITraits {
  function selectTraits(uint256 seed, bool _isZen) external view returns (uint256[] memory t);
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function level(uint256 tokenId) external view returns (uint256);
}