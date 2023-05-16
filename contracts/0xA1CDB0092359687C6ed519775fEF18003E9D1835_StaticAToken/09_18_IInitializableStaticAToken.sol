// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ILendingPool} from './ILendingPool.sol';

/**
 * @title IInitializableStaticAToken
 * @notice Interface for the initialize function on StaticAToken
 * @author Aave
 **/
interface IInitializableStaticAToken {
  /**
   * @dev Emitted when a StaticAToken is initialized
   * @param pool The address of the lending pool where the underlying aToken is used
   * @param aToken The address of the underlying aToken (aWETH)
   * @param staticATokenName The name of the Static aToken
   * @param staticATokenSymbol The symbol of the Static aToken
   **/
  event Initialized(
    address indexed pool,
    address aToken,
    string staticATokenName,
    string staticATokenSymbol
  );

  /**
   * @dev Initializes the StaticAToken
   * @param lendingPool The address of the lending pool where the underlying aToken is used
   * @param aToken The address of the underlying aToken (aWETH)
   * @param staticATokenName The name of the Static aToken
   * @param staticATokenSymbol The symbol of the Static aToken
   */
  function initialize(
    ILendingPool lendingPool,
    address aToken,
    string calldata staticATokenName,
    string calldata staticATokenSymbol
  ) external;
}