// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IHegicPoolV3Migratable {
  event PoolMigrated(address pool, uint256 balance);
  function migrate(address newPool) external;
}