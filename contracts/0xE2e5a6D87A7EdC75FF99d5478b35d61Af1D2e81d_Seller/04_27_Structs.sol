// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Sale {
  bytes32 whitelistRoot;
  bool active;
  uint216 supply;
  uint256 price;
}