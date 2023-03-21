//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IInkNFT {
  function mint(address walletAddress, uint256 quantity) external;

  function totalSupply() external view returns (uint256);
}