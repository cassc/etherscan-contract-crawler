// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ILockupPlans {
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period
  ) external;
}