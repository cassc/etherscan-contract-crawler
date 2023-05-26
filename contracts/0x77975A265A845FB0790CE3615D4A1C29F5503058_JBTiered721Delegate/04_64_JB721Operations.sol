// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JB721Operations {
  // 0...18 - JBOperations
  // 19 - JBOperations2 (ENS/Handle)
  // 20 - JBUriOperations (Set token URI)
  uint256 public constant ADJUST_TIERS = 21;
  uint256 public constant UPDATE_METADATA = 22;
  uint256 public constant SET_RESERVED_BENEFICIARY = 23;
  uint256 public constant MINT = 24;
}