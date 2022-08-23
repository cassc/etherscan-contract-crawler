// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import {TeleportGUID} from "./TeleportGUID.sol";

interface IL1TeleportRouter {
  function requestMint(
    TeleportGUID calldata teleportGUID,
    uint256 maxFeePercentage,
    uint256 operatorFee
  ) external returns (uint256 postFeeAmount, uint256 totalFee);

  function settle(bytes32 targetDomain, uint256 batchedDaiToFlush) external;
}

interface IL1TeleportGateway {
  function l1Token() external view returns (address);

  function l1Escrow() external view returns (address);

  function l1TeleportRouter() external view returns (IL1TeleportRouter);

  function l2TeleportGateway() external view returns (address);

  function finalizeFlush(bytes32 targetDomain, uint256 daiToFlush) external;

  function finalizeRegisterTeleport(TeleportGUID calldata teleport) external;
}

interface IL2TeleportGateway {
  event TeleportInitialized(TeleportGUID teleport);
  event Flushed(bytes32 indexed targetDomain, uint256 dai);

  function l2Token() external view returns (address);

  function l1TeleportGateway() external view returns (address);

  function domain() external view returns (bytes32);

  function initiateTeleport(
    bytes32 targetDomain,
    address receiver,
    uint128 amount
  ) external;

  function initiateTeleport(
    bytes32 targetDomain,
    address receiver,
    uint128 amount,
    address operator
  ) external;

  function initiateTeleport(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) external;

  function flush(bytes32 targetDomain) external;
}