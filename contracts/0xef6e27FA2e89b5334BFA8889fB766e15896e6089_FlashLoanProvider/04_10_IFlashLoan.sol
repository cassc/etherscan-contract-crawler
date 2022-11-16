// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoanProvider {
  function flashLoan(
    address aggregator,
    uint256 value,
    bytes calldata trades,
    uint8 flashLaonType
  ) external;
}

interface IFlashLoanReceiver {
  function onFlashLoanReceived(
    address aggregator,
    uint256 value,
    uint256 fee,
    bytes calldata trades
  ) external;
}

enum FlashLoanType {
  DEFAULT,
  DYDX
}