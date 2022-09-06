// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IExpandedNFT {
  function mintEdition(address to) external payable returns (uint256);
  function mintEditions(address[] memory to) external payable returns (uint256);
  function numberCanMint() external view returns (uint256);
  function owner() external view returns (address);
}