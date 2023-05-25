// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IFlashLoanReceiver} from '../interfaces/IFlashLoanReceiver.sol';
import {IPoolAddressesProvider} from '../../interfaces/IPoolAddressesProvider.sol';
import {IL1Pool} from '../../interfaces/IL1Pool.sol';

/**
 * @title FlashLoanReceiverBase
 *
 * @notice Base contract to develop a flashloan-receiver contract.
 */
abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  IL1Pool public immutable override POOL;

  constructor(IPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    POOL = IL1Pool(provider.getPool());
  }
}