// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {IPool} from './IPool.sol';

/**
 * @title IInitializableHToken
 * @author HopeLend
 * @notice Interface for the initialize function on HToken
 */
interface IInitializableHToken {
  /**
   * @dev Emitted when an hToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param hTokenDecimals The decimals of the underlying
   * @param hTokenName The name of the hToken
   * @param hTokenSymbol The symbol of the hToken
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    uint8 hTokenDecimals,
    string hTokenName,
    string hTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the hToken
   * @param pool The pool contract that is initializing this contract
   * @param treasury The address of the HopeLend treasury, receiving the fees on this hToken
   * @param underlyingAsset The address of the underlying asset of this hToken (E.g. WETH for hWETH)
   * @param hTokenDecimals The decimals of the hToken, same as the underlying asset's
   * @param hTokenName The name of the hToken
   * @param hTokenSymbol The symbol of the hToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address treasury,
    address underlyingAsset,
    uint8 hTokenDecimals,
    string calldata hTokenName,
    string calldata hTokenSymbol,
    bytes calldata params
  ) external;
}