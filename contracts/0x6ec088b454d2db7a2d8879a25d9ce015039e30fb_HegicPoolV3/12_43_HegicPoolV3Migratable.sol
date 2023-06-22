// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import 'hardhat/console.sol';

import '../../../interfaces/HegicPool/V3/IHegicPoolV3.sol';
import '../../../interfaces/HegicPool/V3/IHegicPoolV3Migratable.sol';
import './HegicPoolV3ProtocolParameters.sol';

abstract
contract HegicPoolV3Migratable is HegicPoolV3ProtocolParameters, IHegicPoolV3Migratable {
  function _migrate(address _newPool) internal {
    IHegicPoolV3 newPool = IHegicPoolV3(_newPool);
    require(newPool.isHegicPool(), 'HegicPoolV3Migratable::_migrate::not-setting-a-hegic-pool');
    if (address(lotManager) != address(0)) {
      lotManager.setPool(_newPool);
    }
    zToken.setPool(_newPool);
    uint poolBalance = token.balanceOf(address(this));
    token.transfer(_newPool, poolBalance);
    require(address(newPool.lotManager()) == address(lotManager), 'HegicPoolV3Migratable::_migrate::migrate-lot-manager-discrepancy');
    emit PoolMigrated(_newPool, poolBalance);
  }
}