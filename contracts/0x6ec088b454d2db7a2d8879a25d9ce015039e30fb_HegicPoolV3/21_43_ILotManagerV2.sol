// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../../IGovernable.sol';
import '../../IManageable.sol';
import '../../ICollectableDust.sol';

import '../ILotManagerMetadata.sol';

import './ILotManagerV2ProtocolParameters.sol';
import './ILotManagerV2LotsHandler.sol';
import './ILotManagerV2RewardsHandler.sol';
import './ILotManagerV2Migrable.sol';
import './ILotManagerV2Unwindable.sol';

interface ILotManagerV2 is 
  IGovernable,
  IManageable,
  ICollectableDust,
  ILotManagerMetadata, 
  ILotManagerV2ProtocolParameters, 
  ILotManagerV2LotsHandler,
  ILotManagerV2RewardsHandler,
  ILotManagerV2Migrable,
  ILotManagerV2Unwindable { }