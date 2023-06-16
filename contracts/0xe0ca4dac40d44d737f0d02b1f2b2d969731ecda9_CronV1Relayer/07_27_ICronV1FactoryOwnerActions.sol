// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;

interface ICronV1FactoryOwnerActions {
  function setAdminStatus(address _admin, bool _status) external;

  function setFeeAddress(address _feeDestination) external;

  function setFeeShift(uint256 _feeShift) external;

  function setCollectBalancerFees(bool _collectValue) external;
}