// SPDX-License-Identifier: MIT

library SwapLib {
  struct SwapRecord {
    address token;
    uint64 when;
    uint256 qty;
  }
}