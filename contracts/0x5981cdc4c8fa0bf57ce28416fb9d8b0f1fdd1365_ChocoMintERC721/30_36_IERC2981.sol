// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2981 {
  function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}