// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

interface ILotManagerV2Migrable {
  event LotManagerMigrated(address newLotManager);

  function migrate(address newLotManager) external;
}