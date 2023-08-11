// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {JBSplit} from './JBSplit.sol';

/// @custom:member group The group indentifier.
/// @custom:member splits The splits to associate with the group.
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}