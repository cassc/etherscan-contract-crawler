// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "./IKyokoPoolAddressesProvider.sol";

/**
 * @title IInitializableDebtToken
 * @notice Interface for the initialize function common between debt tokens
 * @author Kyoko
 **/
interface IInitializableDebtToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param reserveId The id of the reserve
   * @param debtTokenDecimals the decimals of the debt token
   * @param debtTokenName the name of the debt token
   * @param debtTokenSymbol the symbol of the debt token
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    uint256 reserveId,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol
  );

  /**
   * @dev Initializes the debt token.
   * @param provider The address of the address provider where this debtToken will be used
   * @param reserveId The id of the reserve
   * @param underlyingAsset The address of the underlying asset of this kToken (E.g. WETH for hWETH)
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   */
  function initialize(
    IKyokoPoolAddressesProvider provider,
    uint256 reserveId,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol
  ) external;
}