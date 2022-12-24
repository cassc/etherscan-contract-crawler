// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMigration {
  function update(address account) external;
}

contract MigrationUpdater is Ownable {
  IMigration public constant updater = IMigration(0x458E7e99344996548Fbc895cb5Ce3E08eC9A7e59);

  function updateBatch(address[] calldata accounts) external onlyOwner {
    for (uint i = 0; i < accounts.length; i++) {
      updater.update(accounts[i]);
    }
  }
}