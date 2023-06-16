// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

interface ICronV1PoolAdminActions {
  function setPause(bool _pauseValue) external;

  function setParameter(uint256 _paramTypeU, uint256 _value) external;

  function setArbitragePartner(address _arbPartner, address _arbitrageList) external;
}