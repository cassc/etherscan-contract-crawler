// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ILendingPool} from './ILendingPool.sol';
import {IViniumIncentivesController} from './IViniumIncentivesController.sol';

/**
 * @title IInitializableViToken
 * @notice Interface for the initialize function on ViToken
 * @author Vinium
 **/
interface IInitializableViToken {
  /**
   * @dev Emitted when an viToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this viToken
   * @param viTokenDecimals the decimals of the underlying
   * @param viTokenName the name of the viToken
   * @param viTokenSymbol the symbol of the viToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 viTokenDecimals,
    string viTokenName,
    string viTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the viToken
   * @param pool The address of the lending pool where this viToken will be used
   * @param treasury The address of the Vinium treasury, receiving the fees on this viToken
   * @param underlyingAsset The address of the underlying asset of this viToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param viTokenDecimals The decimals of the viToken, same as the underlying asset's
   * @param viTokenName The name of the viToken
   * @param viTokenSymbol The symbol of the viToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IViniumIncentivesController incentivesController,
    uint8 viTokenDecimals,
    string calldata viTokenName,
    string calldata viTokenSymbol,
    bytes calldata params
  ) external;
}