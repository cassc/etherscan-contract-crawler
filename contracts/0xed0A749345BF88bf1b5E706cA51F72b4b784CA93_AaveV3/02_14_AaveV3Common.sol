// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title AaveV3Optimism
 *
 * @author Fujidao Labs
 *
 * @notice This contract allows interaction with AaveV3.
 */

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../interfaces/IVault.sol";
import {ILendingProvider} from "../interfaces/ILendingProvider.sol";
import {IV3Pool} from "../interfaces/aaveV3/IV3Pool.sol";
import {AaveEModeHelper} from "./AaveEModeHelper.sol";

abstract contract AaveV3Common is ILendingProvider {
  /**
   * @dev Returns the {IV3Pool} pool to interact with AaveV3
   */
  function _getPool() internal pure virtual returns (IV3Pool);

  /**
   * @dev Returns the {AaveEModeHelper} contract to determine if e-mode is
   * applicable for a vault.
   */
  function _getAaveEModeHelper() internal pure virtual returns (AaveEModeHelper);

  /// @inheritdoc ILendingProvider
  function providerName() public pure virtual override returns (string memory);

  /// @inheritdoc ILendingProvider
  function approvedOperator(
    address,
    address,
    address
  )
    external
    pure
    override
    returns (address operator)
  {
    operator = address(_getPool());
  }

  /// @inheritdoc ILendingProvider
  function deposit(uint256 amount, IVault vault) external override returns (bool success) {
    IV3Pool aave = _getPool();
    address asset = vault.asset();
    aave.supply(asset, amount, address(vault), 0);
    aave.setUserUseReserveAsCollateral(asset, true);
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function borrow(uint256 amount, IVault vault) external override returns (bool success) {
    IV3Pool aave = _getPool();
    _checkAndSetEMode(vault);
    aave.borrow(vault.debtAsset(), amount, 2, 0, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function withdraw(uint256 amount, IVault vault) external override returns (bool success) {
    IV3Pool aave = _getPool();
    aave.withdraw(vault.asset(), amount, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function payback(uint256 amount, IVault vault) external override returns (bool success) {
    IV3Pool aave = _getPool();
    aave.repay(vault.debtAsset(), amount, 2, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function getDepositRateFor(IVault vault) external view override returns (uint256 rate) {
    IV3Pool aaveData = _getPool();
    IV3Pool.ReserveData memory rdata = aaveData.getReserveData(vault.asset());
    rate = rdata.currentLiquidityRate;
  }

  /// @inheritdoc ILendingProvider
  function getBorrowRateFor(IVault vault) external view override returns (uint256 rate) {
    IV3Pool aaveData = _getPool();
    IV3Pool.ReserveData memory rdata = aaveData.getReserveData(vault.debtAsset());
    rate = rdata.currentVariableBorrowRate;
  }

  /// @inheritdoc ILendingProvider
  function getDepositBalance(
    address user,
    IVault vault
  )
    external
    view
    override
    returns (uint256 balance)
  {
    IV3Pool aaveData = _getPool();
    IV3Pool.ReserveData memory rdata = aaveData.getReserveData(vault.asset());
    balance = IERC20(rdata.aTokenAddress).balanceOf(user);
  }

  /// @inheritdoc ILendingProvider
  function getBorrowBalance(
    address user,
    IVault vault
  )
    external
    view
    override
    returns (uint256 balance)
  {
    IV3Pool aaveData = _getPool();
    IV3Pool.ReserveData memory rdata = aaveData.getReserveData(vault.debtAsset());
    balance = IERC20(rdata.variableDebtTokenAddress).balanceOf(user);
  }

  /**
   * @notice Returns true if user already has an e-mode config at `aave` pool.
   *
   * @param user to check e-mode config at AaveV3 pool
   */
  function hasEModeSet(address user) public view returns (bool hasEMode, uint8 config) {
    IV3Pool aave = _getPool();
    config = aave.getUserEMode(user);
    if (config != 0) {
      hasEMode = true;
    }
  }

  /**
   * @dev Checks and sets e-mode at `aave` pool.
   *
   * @param vault to check and set e-mode config at AaveV3 pool
   */
  function _checkAndSetEMode(IVault vault) internal {
    AaveEModeHelper helper = _getAaveEModeHelper();
    uint8 config = helper.getEModeConfigIds(vault.asset(), vault.debtAsset());
    if (config != 0) {
      IV3Pool aave = _getPool();
      (bool hasEMode, uint8 currentConfig) = hasEModeSet(address(vault));
      if (!hasEMode && config != currentConfig) {
        aave.setUserEMode(config);
      }
    }
  }
}