// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {JBFeeType} from './../enums/JBFeeType.sol';

interface IJBFeeGauge3_1 {
  function currentDiscountFor(uint256 projectId, JBFeeType feeType) external view returns (uint256);
}