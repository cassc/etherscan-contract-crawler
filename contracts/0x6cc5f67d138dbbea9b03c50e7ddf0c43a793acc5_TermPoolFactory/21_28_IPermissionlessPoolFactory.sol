// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPermissionlessPoolFactory {
  function isPool(address _pool) external view returns (bool);
}