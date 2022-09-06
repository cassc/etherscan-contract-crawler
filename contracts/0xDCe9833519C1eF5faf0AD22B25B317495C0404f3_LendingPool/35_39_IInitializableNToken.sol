// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ILendingPool} from './ILendingPool.sol';

/**
 * @title IInitializableVToken
 * @notice Interface for the initialize function on NToken
 * @author Aave
 **/
interface IInitializableNToken {
  /**
   * @dev Emitted when an vToken is initialized
   * @param underlyingAsset The address of the underlying NFT asset
   * @param pool The address of the associated lending pool
   * @param nTokenName the name of the NToken
   * @param nTokenSymbol the symbol of the NToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    string nTokenName,
    string nTokenSymbol,
    string baseURI,
    bytes params
  );

  /**
   * @dev Initializes the nToken
   * @param pool The address of the lending pool where this nToken will be used
   * @param underlyingAsset The address of the underlying asset of this nToken
   * @param nTokenName The name of the nToken
   * @param nTokenSymbol The symbol of the nToken
   */
  function initialize(
    ILendingPool pool,
    address underlyingAsset,
    string calldata nTokenName,
    string calldata nTokenSymbol,
    string calldata baseURI,
    bytes calldata params
  ) external;
}