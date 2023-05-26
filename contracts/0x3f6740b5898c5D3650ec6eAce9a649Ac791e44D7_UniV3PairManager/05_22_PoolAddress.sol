// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

library PoolAddress {
  struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
  }
}