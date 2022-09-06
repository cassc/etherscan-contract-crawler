// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ILendingPool} from './ILendingPool.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IInitializableVToken
 * @notice Interface for the initialize function on VToken
 * @author Aave
 **/
interface IInitializableVToken {
  /**
   * @dev Emitted when an vToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this vToken
   * @param vTokenDecimals the decimals of the underlying
   * @param vTokenName the name of the vToken
   * @param vTokenSymbol the symbol of the vToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 vTokenDecimals,
    string vTokenName,
    string vTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the vToken
   * @param pool The address of the lending pool where this vToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this vToken
   * @param underlyingAsset The address of the underlying asset of this vToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param vTokenDecimals The decimals of the vToken, same as the underlying asset's
   * @param vTokenName The name of the vToken
   * @param vTokenSymbol The symbol of the vToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 vTokenDecimals,
    string calldata vTokenName,
    string calldata vTokenSymbol,
    bytes calldata params
  ) external;
}