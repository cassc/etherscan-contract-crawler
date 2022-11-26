// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ITitleEscrowFactory {
  event TitleEscrowCreated(address indexed titleEscrow, address indexed tokenRegistry, uint256 indexed tokenId);

  function implementation() external view returns (address);

  function create(uint256 tokenId) external returns (address);

  function getAddress(address tokenRegistry, uint256 tokenId) external view returns (address);
}