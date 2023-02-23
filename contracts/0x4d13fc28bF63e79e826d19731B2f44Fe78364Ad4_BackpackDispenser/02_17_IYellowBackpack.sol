// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IYellowBackpack {
  function mint(uint256 tokenId, uint256 quantity) external payable;

  function burnToken(address owner, uint256 tokenId) external;

  function allowlistMint(uint256 tokenId, uint256 quantity, bytes calldata signature) external payable;

  function swap(uint256 tokenId, address recipient, uint256 quantity) external;

  function airdrop(uint256 tokenId, address recipient, uint256 quantity) external;

  function airdropBatch(uint256 tokenId, address[] memory recipients, uint256[] memory quantities) external;
}