// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../../interfaces/ILendPoolAddressesProvider.sol";
import {IYVault} from "../../interfaces/yearn/IYVault.sol";

import {DataTypes} from "../../libraries/types/DataTypes.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library LendingLogic {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using WadRayMath for uint256;
  /*//////////////////////////////////////////////////////////////
                          EVENTS
  //////////////////////////////////////////////////////////////*/
  /**
   * @dev Emitted on executeDepositYearn()
   * @param underlyingAsset The UToken's underlying asset deposited
   * @param amount The amount deposited
   * @param yVault The address of the yVault deposited to
   **/
  event DepositYearn(address indexed underlyingAsset, uint256 indexed amount, address yVault);
  /**
   * @dev Emitted on executeWithdrawYearn()
   * @param underlyingAsset The UToken's underlying asset withdrawn
   * @param amount The amount withdrawn
   * @param yVault The address of the yVault withdrawn from
   **/
  event WithdrawYearn(address indexed underlyingAsset, uint256 indexed amount, address yVault);

  /*//////////////////////////////////////////////////////////////
                          INTERNALS
  //////////////////////////////////////////////////////////////*/
  /**
   * @notice Implements the yearn vault deposit feature. Through `executeDepositYearn()`, users supplied assets are deposited into a YVault.
   * @dev Emits the `DepositYearn()` event.
   * @param addressesProvider The protocol current address provider
   * @param params The additional parameters needed to execute the deposit yearn function
   */
  function executeDepositYearn(
    ILendPoolAddressesProvider addressesProvider,
    DataTypes.ExecuteYearnParams memory params
  ) internal {
    address wethAddress = addressesProvider.getAddress(keccak256("WETH"));

    // Only deposit if underlying asset is WETH
    if (params.underlyingAsset == wethAddress) {
      address yVaultWETH = addressesProvider.getAddress(keccak256("YVAULT_WETH"));

      IERC20Upgradeable(params.underlyingAsset).safeApprove(yVaultWETH, params.amount);

      IYVault(yVaultWETH).deposit(params.amount);

      emit DepositYearn(params.underlyingAsset, params.amount, yVaultWETH);
    }
  }

  /**
   * @notice Implements the yearn vault withdraw feature. Through `executeWithdrawYearn()`, users withdrawn assets are withdrawn from the YVault.
   * @dev Emits the `WithdrawYearn()` event.
   * @param addressesProvider The protocol current address provider
   * @param params The additional parameters needed to execute the withdraw yearn function
   */
  function executeWithdrawYearn(
    ILendPoolAddressesProvider addressesProvider,
    DataTypes.ExecuteYearnParams memory params
  ) internal returns (uint256) {
    address wethAddress = addressesProvider.getAddress(keccak256("WETH"));
    // Only withdraw if underlying asset is WETH
    uint256 value;
    if (params.underlyingAsset == wethAddress) {
      address yVaultWETH = addressesProvider.getAddress(keccak256("YVAULT_WETH"));

      uint256 pricePerShare = IYVault(yVaultWETH).pricePerShare();

      uint256 shares = params.amount.wadDiv(pricePerShare);

      value = IYVault(yVaultWETH).withdraw(shares);

      emit WithdrawYearn(params.underlyingAsset, value, yVaultWETH);
    }
    return value;
  }

  /**
   * @notice Implements the yearn vault withdraw feature. Through `executeWithdrawYearn()`, users withdrawn assets are withdrawn from the YVault.
   * @dev Emits the `WithdrawYearn()` event.
   * @param addressesProvider The protocol current address provider
   * @return availableLiquidityInReserve The available liquidity in reserve format
   */
  function calculateYearnAvailableLiquidityInReserve(
    ILendPoolAddressesProvider addressesProvider
  ) internal view returns (uint256 availableLiquidityInReserve) {
    address yVaultWETH = addressesProvider.getAddress(keccak256("YVAULT_WETH"));

    uint256 availableLiquidityInShares = IERC20Upgradeable(yVaultWETH).balanceOf(address(this));

    uint256 pricePerShare = IYVault(yVaultWETH).pricePerShare();

    availableLiquidityInReserve = availableLiquidityInShares.wadMul(pricePerShare);
  }
}