// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IUniFactory {
  function getPair(address tokenA, address tokenB) external view returns (address);
  function allPairsLength() external view returns (uint256);
  function allPairs(uint256) external view returns (address);
}