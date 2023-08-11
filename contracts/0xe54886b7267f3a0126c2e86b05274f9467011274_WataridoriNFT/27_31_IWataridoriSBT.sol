// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWataridoriSBT {
  function mint(address to, bytes32 documentId, uint32 tokenMasterId, uint8 generationNum) external returns (uint256);
}