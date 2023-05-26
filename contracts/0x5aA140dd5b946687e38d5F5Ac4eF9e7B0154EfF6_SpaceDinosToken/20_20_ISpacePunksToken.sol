// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ISpacePunksToken {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
  function totalSupply() external view returns (uint256);
}