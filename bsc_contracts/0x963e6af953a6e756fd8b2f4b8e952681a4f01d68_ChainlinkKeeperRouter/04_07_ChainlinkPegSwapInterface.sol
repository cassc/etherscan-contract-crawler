// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ChainlinkPegSwapInterface {
  function swap(
    uint256 amount,
    address source,
    address target
  ) external;
}
