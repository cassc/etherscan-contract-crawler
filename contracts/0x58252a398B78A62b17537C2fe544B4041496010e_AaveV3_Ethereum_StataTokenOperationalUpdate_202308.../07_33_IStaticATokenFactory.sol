// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaticATokenFactory {
  function getStaticATokens() external returns (address[] memory);
}