// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.7.0 <0.9.0;

import {IERC20} from 'openzeppelin-contracts/token/ERC20/IERC20.sol';
import {ERC20} from 'openzeppelin-contracts/token/ERC20/ERC20.sol';
import {SafeERC20} from 'openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol';
import { IFlashLoanReceiver } from './IFlashLoanReceiver.sol';
import { ILendingPoolAddressesProvider } from './ILendingPoolAddressesProvider.sol';
import { ILendingPool } from './ILendingPool.sol';

/**
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}