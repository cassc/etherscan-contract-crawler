// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IPoolManager {
  function isPoolGenerated(address pool) external view returns (bool);
}