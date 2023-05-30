/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

interface IRewardHandler {
  /**
   * @dev Transfer reward and distribute the fee
   *
   * _to values are in 1e6 factor notation.
   */
  function distribute(
    address _recipient,
    uint256 _amount,
    uint32 _fee,
    uint32 _toTeam,
    uint32 _toMarketing,
    uint32 _toBooster,
    uint32 _toRewardPool
  ) external;
}