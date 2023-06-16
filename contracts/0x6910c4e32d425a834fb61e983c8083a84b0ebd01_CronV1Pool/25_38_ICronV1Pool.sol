// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

pragma experimental ABIEncoderV2;

import { ICronV1FactoryOwnerActions } from "./pool/ICronV1FactoryOwnerActions.sol";
import { ICronV1PoolAdminActions } from "./pool/ICronV1PoolAdminActions.sol";
import { ICronV1PoolArbitrageurActions } from "./pool/ICronV1PoolArbitrageurActions.sol";
import { ICronV1PoolEnums } from "./pool/ICronV1PoolEnums.sol";
import { ICronV1PoolEvents } from "./pool/ICronV1PoolEvents.sol";
import { ICronV1PoolHelpers } from "./pool/ICronV1PoolHelpers.sol";
import { IERC20 } from "../balancer-core-v2/lib/openzeppelin/IERC20.sol";

interface ICronV1Pool is
  ICronV1FactoryOwnerActions,
  ICronV1PoolAdminActions,
  ICronV1PoolArbitrageurActions,
  ICronV1PoolEnums,
  ICronV1PoolEvents,
  ICronV1PoolHelpers,
  IERC20
{}