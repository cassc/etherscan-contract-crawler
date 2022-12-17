// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {ReserveLogic} from './libraries/logic/ReserveLogic.sol';
import {ReserveConfiguration} from './libraries/configuration/ReserveConfiguration.sol';
import {IVaultAddressesProvider} from './interfaces/IVaultAddressesProvider.sol';
import {DataTypes} from './libraries/types/DataTypes.sol';

contract VaultStorage {
  using ReserveLogic for DataTypes.ReserveData;

  IVaultAddressesProvider internal _addressesProvider;

  DataTypes.ReserveData internal _reserve;

  bool internal _paused;

  uint256 internal _whitelistExpiration;

  mapping ( address => uint256 ) internal _whitelist;
}