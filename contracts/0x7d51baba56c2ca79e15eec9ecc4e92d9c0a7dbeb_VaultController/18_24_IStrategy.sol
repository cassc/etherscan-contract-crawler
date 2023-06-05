// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

interface IStrategy {
  function harvest() external;

  function verifyAdapterSelectorCompatibility(bytes4[8] memory sigs) external;

  function verifyAdapterCompatibility(bytes memory data) external;

  function setUp(bytes memory data) external;
}