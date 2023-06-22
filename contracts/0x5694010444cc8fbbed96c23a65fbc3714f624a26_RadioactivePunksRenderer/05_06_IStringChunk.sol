// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.20;

interface IStringChunk {
  function data() external pure returns (string memory);
}