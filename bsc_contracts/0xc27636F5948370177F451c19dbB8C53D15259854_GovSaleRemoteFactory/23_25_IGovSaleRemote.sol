// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGovSaleRemote {
  function init(
    uint128,
    uint128,
    uint128,
    uint128,
    uint128[2] calldata,
    address,
    address
  ) external;

  function finalize(bytes calldata) external;
}