/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ITxWorker
 *
 * @dev ITxWorker is used to create contracts which need transactions
 * to perform maintance tasks. These tasks should be low gas as possible
 * to prevent expensive transaction for the users
 */

interface ITxWorker {
  /**
   * @dev called from external / public functions
   *
   * @param gasLevel level between 0 and 255 about how much gas can be
   * consumed. Implementation dependent. 0 = low gas
   */
  function onTransaction(uint8 gasLevel) external;
}