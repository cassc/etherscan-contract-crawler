// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {JBSplit} from './JBSplit.sol';

/// @custom:member token The token being sent to the split allocator.
/// @custom:member amount The amount being sent to the split allocator, as a fixed point number.
/// @custom:member decimals The number of decimals in the amount.
/// @custom:member projectId The project to which the split belongs.
/// @custom:member group The group to which the split belongs.
/// @custom:member split The split that caused the allocation.
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}