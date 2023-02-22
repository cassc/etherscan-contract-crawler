// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {ILendingPool} from './ILendingPool.sol';
import {IViniumIncentivesController} from './IViniumIncentivesController.sol';

/**
 * @title IInitializableVdToken
 * @notice Interface for the initialize function common between debt tokens
 * @author Vinium
 **/
interface IInitializableVdToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param incentivesController The address of the incentives controller for this viToken
   * @param vdTokenDecimals the decimals of the debt token
   * @param vdTokenName the name of the debt token
   * @param vdTokenSymbol the symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 vdTokenDecimals,
    string vdTokenName,
    string vdTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the debt token.
   * @param pool The address of the lending pool where this viToken will be used
   * @param underlyingAsset The address of the underlying asset of this viToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param vdTokenDecimals The decimals of the vdToken, same as the underlying asset's
   * @param vdTokenName The name of the token
   * @param vdTokenSymbol The symbol of the token
   */
  function initialize(
    ILendingPool pool,
    address underlyingAsset,
    IViniumIncentivesController incentivesController,
    uint8 vdTokenDecimals,
    string memory vdTokenName,
    string memory vdTokenSymbol,
    bytes calldata params
  ) external;
}