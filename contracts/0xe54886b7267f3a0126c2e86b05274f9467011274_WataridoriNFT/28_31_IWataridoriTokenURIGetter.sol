// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IWataridoriTokenURIGetter {
  function getTokenURI(uint8 generationNum, uint32 tokenMasterId) external view returns (string memory);
}