// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SparkSavingsDai
 *
 * @author Fujidao Labs
 *
 * @notice This contract allows direct interaction with Spark's Savings DAI (sDAI).
 *
 * @dev This provider only words for {YieldVaults}. Borrow-state-changing functions revert.
 * Borrow-view functions return zero.
 */

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVault, IERC4626} from "../../interfaces/IVault.sol";
import {IPot} from "../../interfaces/makerdao/IPot.sol";
import {ILendingProvider} from "../../interfaces/ILendingProvider.sol";

contract SparkSavingsDai is ILendingProvider {
  /// Custom errors
  error SparkSavingsDai_deposit_onlySupportDAI();
  error SparkSavingsDai_withdraw_onlySupportDAI();
  error SparkSavingsDai_borrow_notSupported();
  error SparkSavingsDai_payback_notSupported();

  address constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

  uint256 constant ONE_RAY = 10 ** 27;
  uint256 constant ONE_YEAR = 86400 seconds * 365;

  /// @inheritdoc ILendingProvider
  function providerName() external pure returns (string memory) {
    return "SparkSavingsDai";
  }

  /**
   * @dev Returns the Spark's sDAI vault address.
   */
  function _getPool() internal pure returns (IERC4626) {
    return IERC4626(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
  }

  /**
   * @dev Returns the MakerDAO Pot contract address.
   */
  function _getMakerDAOPot() internal pure returns (IPot) {
    return IPot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
  }

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
    IERC4626 sDAI = _getPool();
    address asset = vault.asset();
    if (asset != DAI_ADDRESS) {
      revert SparkSavingsDai_deposit_onlySupportDAI();
    }
    sDAI.deposit(amount, address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function borrow(uint256, IVault) external pure override returns (bool) {
    revert SparkSavingsDai_borrow_notSupported();
  }

  /// @inheritdoc ILendingProvider
  function withdraw(uint256 amount, IVault vault) external override returns (bool success) {
    IERC4626 sDAI = _getPool();
    address asset = vault.asset();
    if (asset != DAI_ADDRESS) {
      revert SparkSavingsDai_withdraw_onlySupportDAI();
    }
    sDAI.withdraw(amount, address(vault), address(vault));
    success = true;
  }

  /// @inheritdoc ILendingProvider
  function payback(uint256, IVault) external pure override returns (bool) {
    revert SparkSavingsDai_payback_notSupported();
  }

  /// @inheritdoc ILendingProvider
  function getDepositRateFor(IVault) external view override returns (uint256 rate) {
    IPot pot = _getMakerDAOPot();
    uint256 dsr = pot.dsr(); // rate of accumulation per second
    rate = (dsr - ONE_RAY) * ONE_YEAR; // ~ close estimate to current APR
  }

  /// @inheritdoc ILendingProvider
  function getBorrowRateFor(IVault) external pure override returns (uint256) {
    return 0;
  }

  /// @inheritdoc ILendingProvider
  function getDepositBalance(address user, IVault) external view override returns (uint256 balance) {
    IERC4626 sDAI = _getPool();
    balance = sDAI.previewRedeem(sDAI.balanceOf(user));
  }

  /// @inheritdoc ILendingProvider
  function getBorrowBalance(address, IVault) external pure override returns (uint256) {
    return 0;
  }

  /**
   * @notice Returns the APY currently in the MakerDAOs savings account.
   * NOTE: This is different than `getDepositRate(...)` which returns the current APR.
   *
   * @dev This method was added for quick reference to compare with sDAI published APY
   * at SparkLend.
   */
  function getAPYforCurrentRateInSparkSavingsDai() external view returns (uint256 apy) {
    IPot pot = _getMakerDAOPot();
    uint256 dsr = pot.dsr();
    uint256 chi = _rpow(dsr, ONE_YEAR, ONE_RAY);
    apy = chi - ONE_RAY;
  }

  /**
   * @dev Returns the accrued amount factor (1 + APR) for a given "dsr" and `n` time lapse in seconds
   * This function was copied *VERBATIM* from:
   *  https://etherscan.deth.net/address/0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7#readContract
   *
   * @param x rate of accrual per second {IPot.dsr()} = saving rate per second
   * @param n time in seconds
   * @param base always 1 RAY
   */
  function _rpow(uint256 x, uint256 n, uint256 base) private pure returns (uint256 z) {
    assembly {
      switch x
      case 0 {
        switch n
        case 0 { z := base }
        default { z := 0 }
      }
      default {
        switch mod(n, 2)
        case 0 { z := base }
        default { z := x }
        let half := div(base, 2) // for rounding.
        for { n := div(n, 2) } n { n := div(n, 2) } {
          let xx := mul(x, x)
          if iszero(eq(div(xx, x), x)) { revert(0, 0) }
          let xxRound := add(xx, half)
          if lt(xxRound, xx) { revert(0, 0) }
          x := div(xxRound, base)
          if mod(n, 2) {
            let zx := mul(z, x)
            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0, 0) }
            let zxRound := add(zx, half)
            if lt(zxRound, zx) { revert(0, 0) }
            z := div(zxRound, base)
          }
        }
      }
    }
  }
}