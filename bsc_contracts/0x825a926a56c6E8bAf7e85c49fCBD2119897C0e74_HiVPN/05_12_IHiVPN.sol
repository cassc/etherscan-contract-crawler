// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

interface IHiVPN {
  function toToken(address token, uint256 value) external view returns (uint256);

  function toUSD(address token, uint256 value) external view returns (uint256);

  function findPlan(uint256 value) external view returns (uint8);

  function pay(
    uint256 id,
    uint256 plan,
    address token,
    uint256 amount,
    address referrer
  ) external payable;
}