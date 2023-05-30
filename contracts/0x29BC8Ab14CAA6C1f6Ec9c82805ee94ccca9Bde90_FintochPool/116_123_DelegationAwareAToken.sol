// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IL1Pool} from '../../interfaces/IL1Pool.sol';
import {IDelegationToken} from '../../interfaces/IDelegationToken.sol';
import {AToken} from './AToken.sol';

/**
 * @title DelegationAwareAToken
 *
 * @notice AToken enabled to delegate voting power of the underlying asset to a different address
 * @dev The underlying asset needs to be compatible with the COMP delegation interface
 */
contract DelegationAwareAToken is AToken {
  /**
   * @dev Emitted when underlying voting power is delegated
   * @param delegatee The address of the delegatee
   */
  event DelegateUnderlyingTo(address indexed delegatee);

  /**
   * @dev Constructor.
   * @param pool The address of the Pool contract
   */
  constructor(IL1Pool pool) AToken(pool) {
    // Intentionally left blank
  }

  /**
   * @notice Delegates voting power of the underlying asset to a `delegatee` address
   * @param delegatee The address that will receive the delegation
   **/
  function delegateUnderlyingTo(address delegatee) external onlyPoolAdmin {
    IDelegationToken(_underlyingAsset).delegate(delegatee);
    emit DelegateUnderlyingTo(delegatee);
  }
}