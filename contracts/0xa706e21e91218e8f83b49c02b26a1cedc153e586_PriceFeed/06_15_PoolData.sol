// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct PoolData {
  address poolAddress;
  uint24 fee;
  uint48 lastUpdatedTimestamp;
}