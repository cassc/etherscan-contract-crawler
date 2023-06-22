// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../../IGovernable.sol';
import '../../IManageable.sol';
import '../../ICollectableDust.sol';

import '../IHegicPoolMetadata.sol';

import './IHegicPoolV3ProtocolParameters.sol';
import './IHegicPoolV3LotManager.sol';
import './IHegicPoolV3Depositable.sol';
import './IHegicPoolV3Withdrawable.sol';
import './IHegicPoolV3Migratable.sol';

interface IHegicPoolV3 is 
  IGovernable,
  IManageable,
  ICollectableDust,
  IHegicPoolMetadata, 
  IHegicPoolV3ProtocolParameters, 
  IHegicPoolV3LotManager,
  IHegicPoolV3Depositable,
  IHegicPoolV3Withdrawable,
  IHegicPoolV3Migratable { }