// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IBackpackOracle {
  function selectTokens(uint256 quantity) external payable returns (uint256[] memory tokenIds);
}