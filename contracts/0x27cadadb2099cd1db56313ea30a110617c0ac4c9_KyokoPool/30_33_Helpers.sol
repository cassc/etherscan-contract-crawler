// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../../interfaces/IStableDebtToken.sol";
import "../../interfaces/IVariableDebtToken.sol";
import "./DataTypes.sol";

/**
 * @title Helpers library
 * @author Kyoko
 */
library Helpers {
  /**
   * @dev Fetches the user current stable and variable debt balances
   * @param user The user address
   * @param reserve The reserve data object
   * @return The stable and variable debt balance
   **/
  function getUserCurrentDebt(address user, DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IERC20Upgradeable(reserve.stableDebtTokenAddress).balanceOf(user),
      IERC20Upgradeable(reserve.variableDebtTokenAddress).balanceOf(user)
    );
  }

  function getUserCurrentDebtMemory(address user, DataTypes.ReserveData memory reserve)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IERC20Upgradeable(reserve.stableDebtTokenAddress).balanceOf(user),
      IERC20Upgradeable(reserve.variableDebtTokenAddress).balanceOf(user)
    );
  }
  /**
   * @dev Fetches the user specific amount's stable and variable debt balances
   * @param user The user address
   * @param reserve The reserve data object
   * @return The stable and variable debt balance
   **/
  function getUserDebtOfAmount(address user, DataTypes.ReserveData storage reserve, uint256 amount)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IStableDebtToken(reserve.stableDebtTokenAddress).balanceOfAmount(user, amount),
      IVariableDebtToken(reserve.variableDebtTokenAddress).balanceOfAmount(user, amount)
    );
  }

  function getUserDebtOfAmountMemory(address user, DataTypes.ReserveData memory reserve, uint256 amount)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      IStableDebtToken(reserve.stableDebtTokenAddress).balanceOfAmount(user, amount),
      IVariableDebtToken(reserve.variableDebtTokenAddress).balanceOfAmount(user, amount)
    );
  }
}