// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IACLManager, IPoolConfigurator} from 'lib/aave-address-book/src/AaveV3.sol';

/// @dev Contract for an Aave EMERGENCY_ADMIN to be able to also freeze/unfreeze assets
/// This contract should receive any role allowing for freezing (e.g. RIKS_ADMIN)
contract FreezingSteward {
  IACLManager public immutable ACL_MANAGER;
  IPoolConfigurator public immutable POOL_CONFIGURATOR;

  constructor(IACLManager aclManager, IPoolConfigurator poolConfigurator) {
    ACL_MANAGER = aclManager;
    POOL_CONFIGURATOR = poolConfigurator;
  }

  function setFreeze(address asset, bool freeze) external {
    require(ACL_MANAGER.isEmergencyAdmin(msg.sender), 'ONLY_EMERGENCY_ADMIN');
    POOL_CONFIGURATOR.setReserveFreeze(asset, freeze);
  }
}