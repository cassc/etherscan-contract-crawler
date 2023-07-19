//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ENSReverseClaimer} from '../ENSReverseClaimer.sol';
import {KeepAlive} from '../KeepAlive.sol';

/**
 * @title TestENSReverseClaimer
 * @dev This contract is test contract to test functionality for
 *     ENSReverseClaimer.
 */
contract TestENSReverseClaimer is KeepAlive, ENSReverseClaimer {
  constructor(address owner) {
    transferOwnership(owner);
  }
}