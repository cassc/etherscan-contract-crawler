// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {IVault} from './IVault.sol';

/**
 * @title IInitializableOToken
 * @notice Interface for the initialize function on OToken
 * @author Aave
 * @author Onebit
 **/
interface IInitializableOToken {
  /**
   * @dev Emitted when an oToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param vault The address of the associated vault
   * @param oTokenDecimals the decimals of the underlying
   * @param oTokenName the name of the oToken
   * @param oTokenSymbol the symbol of the oToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed vault,
    uint8 oTokenDecimals,
    string oTokenName,
    string oTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the oToken
   * @param vault The address of the vault where this oToken will be used
   * @param underlyingAsset The address of the underlying asset of this oToken (E.g. WETH for aWETH)
   * @param oTokenDecimals The decimals of the oToken, same as the underlying asset's
   * @param oTokenName The name of the oToken
   * @param oTokenSymbol The symbol of the oToken
   */
  function initialize(
    IVault vault,
    address underlyingAsset,
    uint8 oTokenDecimals,
    string calldata oTokenName,
    string calldata oTokenSymbol,
    bytes calldata params
  ) external;
}