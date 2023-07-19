// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.20;

interface IBytesChunk {
  function data() external pure returns (bytes memory);
}