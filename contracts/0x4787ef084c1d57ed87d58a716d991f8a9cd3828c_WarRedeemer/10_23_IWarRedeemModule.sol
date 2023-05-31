// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IWarRedeemModule {
  function queuedForWithdrawal(address token) external returns (uint256);
  function notifyUnlock(address token, uint256 amount) external;
}