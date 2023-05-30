// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRemixOriginal {
  function mint(uint256 _quantity) external payable;
  function mintWithTokens(uint256 _numGoldTokens, uint256 _basicGoldTokens) external payable;
}