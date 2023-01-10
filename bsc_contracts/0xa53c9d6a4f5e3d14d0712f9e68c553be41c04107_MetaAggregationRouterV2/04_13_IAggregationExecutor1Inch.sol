// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

interface IAggregationExecutor1Inch {
  function callBytes(address msgSender, bytes calldata data) external payable; // 0x2636f7f8
}

interface IAggregationRouter1InchV4 {
  function swap(
    IAggregationExecutor1Inch caller,
    SwapDescription1Inch calldata desc,
    bytes calldata data
  ) external payable returns (uint256 returnAmount, uint256 gasLeft);
}

struct SwapDescription1Inch {
  IERC20 srcToken;
  IERC20 dstToken;
  address payable srcReceiver;
  address payable dstReceiver;
  uint256 amount;
  uint256 minReturnAmount;
  uint256 flags;
  bytes permit;
}

struct SwapDescriptionExecutor1Inch {
  IERC20 srcToken;
  IERC20 dstToken;
  address payable srcReceiver1Inch;
  address payable dstReceiver;
  address[] srcReceivers;
  uint256[] srcAmounts;
  uint256 amount;
  uint256 minReturnAmount;
  uint256 flags;
  bytes permit;
}