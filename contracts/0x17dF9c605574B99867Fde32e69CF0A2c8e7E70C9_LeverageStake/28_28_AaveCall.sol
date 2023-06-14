pragma solidity 0.6.12;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {ILendingPool} from '../interfaces/IAggregationInterface.sol';
import {IETF} from '../interfaces/IETF.sol';

/**
 * @title AaveCall
 * @author Desyn Protocol
 *
 * Collection of helper functions for interacting with AaveCall integrations.
 */
library AaveCall {
  /* ============ External ============ */

  /**
   * Get deposit calldata from ETF
   *
   * Deposits an `_amountNotional` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to deposit
   * @param _amountNotional       The amount to be deposited
   * @param _onBehalfOf           The address that will receive the aTokens, same as msg.sender if the user
   *                              wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *                              is a different wallet
   * @param _referralCode         Code used to register the integrator originating the operation, for potential rewards.
   *                              0 if the action is executed directly by the user, without any middle-man
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Deposit calldata
   */
  function getDepositCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    address _onBehalfOf,
    uint16 _referralCode
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'deposit(address,uint256,address,uint16)',
      _asset,
      _amountNotional,
      _onBehalfOf,
      _referralCode
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke deposit on LendingPool from ETF
   *
   * Deposits an `_amountNotional` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. ETF deposits 100 USDC and gets in return 100 aUSDC
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to deposit
   * @param _amountNotional       The amount to be deposited
   */
  function invokeDeposit(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional
  ) internal {
    (, , bytes memory depositCalldata) = getDepositCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      address(_etf.bPool()),
      0
    );

    _etf.execute(address(_lendingPool), 0, depositCalldata, true);
  }

  /**
   * Get withdraw calldata from ETF
   *
   * Withdraws an `_amountNotional` of underlying asset from the reserve, burning the equivalent aTokens owned
   * - E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to withdraw
   * @param _amountNotional       The underlying amount to be withdrawn
   *                              Note: Passing type(uint256).max will withdraw the entire aToken balance
   * @param _receiver             Address that will receive the underlying, same as msg.sender if the user
   *                              wants to receive it on his own wallet, or a different address if the beneficiary is a
   *                              different wallet
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Withdraw calldata
   */
  function getWithdrawCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    address _receiver
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'withdraw(address,uint256,address)',
      _asset,
      _amountNotional,
      _receiver
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke withdraw on LendingPool from ETF
   *
   * Withdraws an `_amountNotional` of underlying asset from the reserve, burning the equivalent aTokens owned
   * - E.g. ETF has 100 aUSDC, and receives 100 USDC, burning the 100 aUSDC
   *
   * @param _etf         Address of the ETF
   * @param _lendingPool      Address of the LendingPool contract
   * @param _asset            The address of the underlying asset to withdraw
   * @param _amountNotional   The underlying amount to be withdrawn
   *                          Note: Passing type(uint256).max will withdraw the entire aToken balance
   *
   * @return uint256          The final amount withdrawn
   */
  function invokeWithdraw(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional
  ) internal returns (uint256) {
    (, , bytes memory withdrawCalldata) = getWithdrawCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      address(_etf.bPool())
    );

    return abi.decode(_etf.execute(address(_lendingPool), 0, withdrawCalldata, true), (uint256));
  }

  /**
   * Get borrow calldata from ETF
   *
   * Allows users to borrow a specific `_amountNotional` of the reserve underlying `_asset`, provided that
   * the borrower already deposited enough collateral, or he was given enough allowance by a credit delegator
   * on the corresponding debt token (StableDebtToken or VariableDebtToken)
   *
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to borrow
   * @param _amountNotional       The amount to be borrowed
   * @param _interestRateMode     The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param _referralCode         Code used to register the integrator originating the operation, for potential rewards.
   *                              0 if the action is executed directly by the user, without any middle-man
   * @param _onBehalfOf           Address of the user who will receive the debt. Should be the address of the borrower itself
   *                              calling the function if he wants to borrow against his own collateral, or the address of the
   *                              credit delegator if he has been given credit delegation allowance
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Borrow calldata
   */
  function getBorrowCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode,
    uint16 _referralCode,
    address _onBehalfOf
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'borrow(address,uint256,uint256,uint16,address)',
      _asset,
      _amountNotional,
      _interestRateMode,
      _referralCode,
      _onBehalfOf
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke borrow on LendingPool from ETF
   *
   * Allows ETF to borrow a specific `_amountNotional` of the reserve underlying `_asset`, provided that
   * the ETF already deposited enough collateral, or it was given enough allowance by a credit delegator
   * on the corresponding debt token (StableDebtToken or VariableDebtToken)
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset to borrow
   * @param _amountNotional       The amount to be borrowed
   * @param _interestRateMode     The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   */
  function invokeBorrow(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode,
    uint16 referralCode
  ) internal {
    (, , bytes memory borrowCalldata) = getBorrowCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      _interestRateMode,
      referralCode,
      address(_etf.bPool())
    );

    _etf.execute(address(_lendingPool), 0, borrowCalldata, true);
  }

  /**
   * Get repay calldata from ETF
   *
   * Repays a borrowed `_amountNotional` on a specific `_asset` reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the borrowed underlying asset previously borrowed
   * @param _amountNotional       The amount to repay
   *                              Note: Passing type(uint256).max will repay the whole debt for `_asset` on the specific `_interestRateMode`
   * @param _interestRateMode     The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param _onBehalfOf           Address of the user who will get his debt reduced/removed. Should be the address of the
   *                              user calling the function if he wants to reduce/remove his own debt, or the address of any other
   *                              other borrower whose debt should be removed
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                Repay calldata
   */
  function getRepayCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode,
    address _onBehalfOf
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'repay(address,uint256,uint256,address)',
      _asset,
      _amountNotional,
      _interestRateMode,
      _onBehalfOf
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke repay on LendingPool from ETF
   *
   * Repays a borrowed `_amountNotional` on a specific `_asset` reserve, burning the equivalent debt tokens owned
   * - E.g. ETF repays 100 USDC, burning 100 variable/stable debt tokens
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the borrowed underlying asset previously borrowed
   * @param _amountNotional       The amount to repay
   *                              Note: Passing type(uint256).max will repay the whole debt for `_asset` on the specific `_interestRateMode`
   * @param _interestRateMode     The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   *
   * @return uint256              The final amount repaid
   */
  function invokeRepay(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amountNotional,
    uint256 _interestRateMode
  ) internal returns (uint256) {
    (, , bytes memory repayCalldata) = getRepayCalldata(
      _lendingPool,
      _asset,
      _amountNotional,
      _interestRateMode,
      address(_etf.bPool())
    );

    return abi.decode(_etf.execute(address(_lendingPool), 0, repayCalldata, true), (uint256));
  }

  /**
   * Get setUserUseReserveAsCollateral calldata from ETF
   *
   * Allows borrower to enable/disable a specific deposited asset as collateral
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset deposited
   * @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
   *
   * @return address              Target contract address
   * @return uint256              Call value
   * @return bytes                SetUserUseReserveAsCollateral calldata
   */
  function getSetUserUseReserveAsCollateralCalldata(
    ILendingPool _lendingPool,
    address _asset,
    bool _useAsCollateral
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'setUserUseReserveAsCollateral(address,bool)',
      _asset,
      _useAsCollateral
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke an asset to be used as collateral on Aave from ETF
   *
   * Allows ETF to enable/disable a specific deposited asset as collateral
   * @param _etf             Address of the ETF
   * @param _lendingPool          Address of the LendingPool contract
   * @param _asset                The address of the underlying asset deposited
   * @param _useAsCollateral      true` if the user wants to use the deposit as collateral, `false` otherwise
   */
  function invokeSetUserUseReserveAsCollateral(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    bool _useAsCollateral
  ) internal {
    (, , bytes memory callData) = getSetUserUseReserveAsCollateralCalldata(
      _lendingPool,
      _asset,
      _useAsCollateral
    );

    _etf.execute(address(_lendingPool), 0, callData, true);
  }

  /**
   * Get swapBorrowRate calldata from ETF
   *
   * Allows a borrower to toggle his debt between stable and variable mode
   * @param _lendingPool      Address of the LendingPool contract
   * @param _asset            The address of the underlying asset borrowed
   * @param _rateMode         The rate mode that the user wants to swap to
   *
   * @return address          Target contract address
   * @return uint256          Call value
   * @return bytes            SwapBorrowRate calldata
   */
  function getSwapBorrowRateModeCalldata(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _rateMode
  ) internal pure returns (address, uint256, bytes memory) {
    bytes memory callData = abi.encodeWithSignature(
      'swapBorrowRateMode(address,uint256)',
      _asset,
      _rateMode
    );

    return (address(_lendingPool), 0, callData);
  }

  /**
   * Invoke to swap borrow rate of ETF
   *
   * Allows ETF to toggle it's debt between stable and variable mode
   * @param _etf         Address of the ETF
   * @param _lendingPool      Address of the LendingPool contract
   * @param _asset            The address of the underlying asset borrowed
   * @param _rateMode         The rate mode that the user wants to swap to
   */
  function invokeSwapBorrowRateMode(
    IETF _etf,
    ILendingPool _lendingPool,
    address _asset,
    uint256 _rateMode
  ) internal {
    (, , bytes memory callData) = getSwapBorrowRateModeCalldata(_lendingPool, _asset, _rateMode);

    _etf.execute(address(_lendingPool), 0, callData, true);
  }
}