// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

import { FixedPointMathLib } from "./utils/FixedPointMathLib.sol";
import "./utils/ModuleStateCoder.sol";
import { ZeroBTCStorage } from "./storage/ZeroBTCStorage.sol";

/**
 * @notice Base contract that must be inherited by all modules.
 */
abstract contract BaseModule is ZeroBTCStorage {
  using ModuleStateCoder for ModuleState;
  using FixedPointMathLib for uint256;

  /// @notice Base asset of the vault which is calling the module.
  /// This value is private because it is read only to the module.
  address public immutable asset;

  /// @notice Isolated storage pointer for any data that the module must write
  /// Use like so:
  address internal immutable _moduleSlot;

  constructor(address _asset) {
    asset = _asset;
    _moduleSlot = address(this);
  }

  function initialize() external virtual {}

  function _getModuleState() internal returns (ModuleState moduleState) {
    moduleState = _moduleFees[_moduleSlot];
  }

  /**
   * @notice Repays a loan.
   *
   * This is always called in a delegatecall.
   *
   * `collateralToUnlock` should be equal to `repaidAmount` unless the vault
   * has less than 100% collateralization or the loan is underpaid.
   *
   * @param borrower Recipient of the loan
   * @param repaidAmount Amount of `asset` being repaid.
   * @param loanId Unique (per vault) identifier for a loan.
   * @param data Any additional data provided to the module.
   * @return collateralToUnlock Amount of collateral to unlock for the lender.
   */
  function repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) external virtual returns (uint256 collateralToUnlock) {
    // Handle loan using module's logic, reducing borrow amount by the value of gas used
    collateralToUnlock = _repayLoan(borrower, repaidAmount, loanId, data);
  }

  /**
   * @notice Take out a loan.
   *
   * This is always called in a delegatecall.
   *
   * `collateralToLock` should be equal to `borrowAmount` unless the vault
   * has less than 100% collateralization.
   *
   * @param borrower Recipient of the loan
   * @param borrowAmount Amount of `asset` being borrowed.
   * @param loanId Unique (per vault) identifier for a loan.
   * @param data Any additional data provided to the module.
   * @return collateralToLock Amount of collateral to lock for the lender.
   */
  function receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) external virtual returns (uint256 collateralToLock) {
    // Handle loan using module's logic, reducing borrow amount by the value of gas used
    collateralToLock = _receiveLoan(borrower, borrowAmount, loanId, data);
  }

  struct ConvertLocals {
    address borrower;
    uint256 minOut;
    uint256 amount;
    uint256 nonce;
  }

  /* ---- Override These In Child ---- */
  function swap(ConvertLocals memory) internal virtual returns (uint256 amountOut);

  function swapBack(ConvertLocals memory) internal virtual returns (uint256 amountOut);

  function transfer(address to, uint256 amount) internal virtual;

  function _receiveLoan(
    address borrower,
    uint256 borrowAmount,
    uint256 loanId,
    bytes calldata data
  ) internal virtual returns (uint256 collateralToLock);

  function _repayLoan(
    address borrower,
    uint256 repaidAmount,
    uint256 loanId,
    bytes calldata data
  ) internal virtual returns (uint256 collateralToUnlock);

  /* ---- Leave Empty For Now ---- */

  /// @notice Return recent average gas price in wei per unit of gas
  function getGasPrice() internal view virtual returns (uint256) {
    return 1;
  }

  /// @notice Get current price of ETH in terms of `asset`
  function getEthPrice() internal view virtual returns (uint256) {
    return 1;
  }
}

contract ABC {
  function x(uint256 a) external pure {
    assembly {
      a := or(shr(96, a), or(shr(96, a), or(shr(96, a), or(shr(96, a), or(shr(96, a), shr(96, a))))))
    }
  }
}