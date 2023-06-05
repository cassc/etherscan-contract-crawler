// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IRatios {
  function getTokenRatio(address token) external view returns (uint256);
  function addToken(address token, uint256 maxSupply) external;
  function getMintAmount(address token, uint256 amount) external view returns (uint256 mintAmount);
  function getBurnAmount(address token, uint256 amount) external view returns (uint256 burnAmount);
}