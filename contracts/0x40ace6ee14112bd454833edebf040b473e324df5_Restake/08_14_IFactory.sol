// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IFactory {
  function getPool(
    address token0,
    address token1,
    uint24 fee
  ) external returns (address);
}