// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IFeeReceiver {
  function onFeesReceived(
    address stake,
    address asset,
    uint256 amount
  ) external;
}