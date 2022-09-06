// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRenderer {
  function uri(uint256 tokenId) external view returns (string memory);
}