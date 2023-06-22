// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicPoolV3Withdrawable {
  event Withdrew(address withdrawer, uint256 burntShares, uint256 withdrawedTokens);
  function withdraw(uint256 shares) external returns (uint256 underlyingToWithdraw);
  function withdrawAll() external returns (uint256 underlyingToWithdraw);
}