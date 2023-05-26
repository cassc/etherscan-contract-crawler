// SPDX-License-Identifier: MIT
// Non-Fungible Labs

pragma solidity ^0.8.16;

interface IThingiesArtNFT {
  function mint(address walletAddress, uint256 quantity) external;

  function totalSupply() external view returns (uint256);
}