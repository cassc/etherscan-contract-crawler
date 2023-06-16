// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

interface ICronV1PoolArbitrageurActions {
  function updateArbitrageList() external returns (address);

  function executeVirtualOrdersToBlock(uint256 _maxBlock) external;
}