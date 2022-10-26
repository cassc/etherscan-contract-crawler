// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IMooCard {
  function currentTokenId() external view returns (uint256);

  function mintCard(address to, uint256 category) external;
}