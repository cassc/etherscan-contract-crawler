// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

library Helpers {
  function requireNonZeroAddress(address addr) internal pure {
    require(addr != address(0x0), "Address can't be Zero");
  }
}