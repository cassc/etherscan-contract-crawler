// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct Contribution {
  uint256 timestamp;
  uint16 epochNumber;
  address contributor;
  string description;
  string proofURL;
  uint8 hoursSpent;
  uint8 alignmentPercentage;
}