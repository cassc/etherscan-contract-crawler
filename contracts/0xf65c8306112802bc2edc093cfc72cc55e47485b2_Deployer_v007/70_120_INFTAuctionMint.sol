// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTAuctionMint {
  function mintFor(address) external returns (uint256);

  function transferFrom(address from, address to, uint256 id) external;

  function unitPrice() external view returns (uint256);
}