// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {IGeneralVault} from '../../interfaces/IGeneralVault.sol';
import {IAToken} from '../../interfaces/IAToken.sol';
import {IFlashLoanReceiver} from '../../flashloan/interfaces/IFlashLoanReceiver.sol';
import {IAaveFlashLoan} from '../../interfaces/IAaveFlashLoan.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {Math} from '../../dependencies/openzeppelin/contracts/Math.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';

contract GeneralLevSwap is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;

  uint256 private constant SAFE_BUFFER = 5000;

  uint256 private constant USE_VARIABLE_DEBT = 2;

  address private constant AAVE_LENDING_POOL_ADDRESS = 0x7937D4799803FbBe595ed57278Bc4cA21f3bFfCB;

  address public immutable COLLATERAL; // The addrss of external asset

  uint256 public immutable DECIMALS; // The collateral decimals

  address public immutable VAULT; // The address of vault

  ILendingPoolAddressesProvider internal immutable PROVIDER;

  IPriceOracleGetter internal immutable ORACLE;

  ILendingPool internal immutable LENDING_POOL;

  mapping(address => bool) ENABLED_STABLE_COINS;

  event EnterPosition(
    uint256 amount,
    uint256 iterations,
    uint256 ltv,
    address indexed borrowedCoin
  );

  event LeavePosition(uint256 amount, address indexed borrowedCoin);

  /**
   * @param _asset The external asset ex. wFTM
   * @param _vault The deployed vault address
   * @param _provider The deployed AddressProvider
   */
  constructor(
    address _asset,
    address _vault,
    address _provider
  ) {
    require(
      _asset != address(0) && _provider != address(0) && _vault != address(0),
      Errors.LS_INVALID_CONFIGURATION
    );

    COLLATERAL = _asset;
    DECIMALS = IERC20Detailed(_asset).decimals();
    VAULT = _vault;
    PROVIDER = ILendingPoolAddressesProvider(_provider);
    ORACLE = IPriceOracleGetter(PROVIDER.getPriceOracle());
    LENDING_POOL = ILendingPool(PROVIDER.getLendingPool());
    IERC20(COLLATERAL).approve(_vault, type(uint256).max);
  }

  /**
   * Get stable coins available to borrow
   */
  function getAvailableStableCoins() external pure virtual returns (address[] memory) {
    return new address[](0);
  }

  function _getAssetPrice(address _asset) internal view returns (uint256) {
    return ORACLE.getAssetPrice(_asset);
  }

  /**
   * This function is called after your contract has received the flash loaned amount
   * overriding executeOperation() in IFlashLoanReceiver
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address,
    bytes calldata params
  ) external override returns (bool) {
    _executeOperation(assets[0], amounts[0], premiums[0], params);

    // approve the Aave LendingPool contract allowance to *pull* the owed amount
    IERC20(assets[0]).safeApprove(AAVE_LENDING_POOL_ADDRESS, 0);
    IERC20(assets[0]).safeApprove(AAVE_LENDING_POOL_ADDRESS, amounts[0] + premiums[0]);

    return true;
  }

  function _executeOperation(
    address asset,
    uint256 borrowAmount,
    uint256 fee,
    bytes calldata params
  ) internal {
    // parse params
    (bool isEnterPosition, uint256 arg0, uint256 arg1, address arg2, address arg3) = abi.decode(
      params,
      (bool, uint256, uint256, address, address)
    );
    if (isEnterPosition) {
      _enterPositionWithFlashloan(arg1, arg2, asset, borrowAmount, fee);
    } else {
      // _leavePositionWithFlashloan(arg0, arg1, arg2, arg3, asset, borrowAmount);
      _withdrawWithFlashloan(arg0, arg1, arg2, arg3, asset, borrowAmount);
    }
  }

  /**
   * @param _principal - The amount of collateral
   * @param _iterations - Loop count
   * @param _ltv - The loan to value of the asset in 4 decimals ex. 82.5% == 82_50
   * @param _stableAsset - The borrowing stable coin address when leverage works
   */
  function enterPosition(
    uint256 _principal,
    uint256 _iterations,
    uint256 _ltv,
    address _stableAsset
  ) external {
    require(_principal > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(ENABLED_STABLE_COINS[_stableAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(IERC20(COLLATERAL).balanceOf(msg.sender) >= _principal, Errors.LS_SUPPLY_NOT_ALLOWED);

    IERC20(COLLATERAL).safeTransferFrom(msg.sender, address(this), _principal);

    _supply(_principal, msg.sender);

    uint256 suppliedAmount = _principal;
    uint256 borrowAmount = 0;
    uint256 stableAssetDecimals = IERC20Detailed(_stableAsset).decimals();
    for (uint256 i; i < _iterations; ++i) {
      borrowAmount = _calcBorrowableAmount(suppliedAmount, _ltv, _stableAsset, stableAssetDecimals);
      if (borrowAmount > 0) {
        // borrow stable coin
        _borrow(_stableAsset, borrowAmount, msg.sender);
        // swap stable coin to collateral
        suppliedAmount = _swapTo(_stableAsset, borrowAmount);
        // supply to LP
        _supply(suppliedAmount, msg.sender);
      }
    }

    emit EnterPosition(_principal, _iterations, _ltv, _stableAsset);
  }

  /**
   * @param _principal - The amount of collateral
   * @param _leverage - Extra leverage value and must be greater than 0, ex. 300% = 300_00
   *                    _principal + _principal * _leverage should be used as collateral
   * @param _slippage - Slippage valule to borrow enough asset by flashloan,
   *                    Must be greater than 0%.
   *                    Borrowing amount = _principal * _leverage * _slippage
   * @param _stableAsset - The borrowing stable coin address when leverage works
   */
  function enterPositionWithFlashloan(
    uint256 _principal,
    uint256 _leverage,
    uint256 _slippage,
    address _stableAsset
  ) external {
    require(_principal > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_leverage > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_slippage > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(ENABLED_STABLE_COINS[_stableAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(IERC20(COLLATERAL).balanceOf(msg.sender) >= _principal, Errors.LS_SUPPLY_NOT_ALLOWED);

    IERC20(COLLATERAL).safeTransferFrom(msg.sender, address(this), _principal);

    IAaveFlashLoan AAVE_LENDING_POOL = IAaveFlashLoan(AAVE_LENDING_POOL_ADDRESS);
    uint256 stableAssetDecimals = IERC20Detailed(_stableAsset).decimals();

    address[] memory assets = new address[](1);
    assets[0] = _stableAsset;

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = ((((_principal * _getAssetPrice(COLLATERAL)) / 10**DECIMALS) *
      10**stableAssetDecimals) / _getAssetPrice(_stableAsset)).percentMul(_leverage).percentMul(
        PercentageMath.PERCENTAGE_FACTOR + _slippage
      );

    // 0 means revert the transaction if not validated
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    uint256 minCollateralAmount = _principal.percentMul(
      PercentageMath.PERCENTAGE_FACTOR + _leverage
    );
    bytes memory params = abi.encode(
      true, /*enterPosition*/
      0,
      minCollateralAmount,
      msg.sender,
      address(0)
    );

    AAVE_LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
  }

  /**
   * @param _principal - The amount of collateral, uint256 max value should withdraw all collateral
   * @param _slippage - The slippage of the every withdrawal amount. 1% = 100
   * @param _iterations - Loop count
   * @param _stableAsset - The borrowing stable coin address when leverage works
   * @param _sAsset - staked asset address of collateral internal asset
   */
  function leavePosition(
    uint256 _principal,
    uint256 _slippage,
    uint256 _iterations,
    address _stableAsset,
    address _sAsset
  ) external {
    require(_principal > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(ENABLED_STABLE_COINS[_stableAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(_sAsset != address(0), Errors.LS_INVALID_CONFIGURATION);

    DataTypes.ReserveConfigurationMap memory configuration = LENDING_POOL.getConfiguration(
      IAToken(_sAsset).UNDERLYING_ASSET_ADDRESS()
    );
    (, uint256 assetLiquidationThreshold, , , ) = configuration.getParamsMemory();
    require(assetLiquidationThreshold != 0, Errors.LS_INVALID_CONFIGURATION);

    (, , , uint256 liquidationThreshold, uint256 ltv, ) = LENDING_POOL.getUserAccountData(
      msg.sender
    );
    uint256 normalHealthFactor = (WadRayMath.wad() * liquidationThreshold) / ltv;
    address variableDebtTokenAddress = LENDING_POOL
      .getReserveData(_stableAsset)
      .variableDebtTokenAddress;

    // reduce leverage to increase healthFactor
    if (_iterations > 0) {
      _reduceLeverageWithAmount(_sAsset, _stableAsset, _slippage, assetLiquidationThreshold, 0);
    } else {
      _reduceLeverageWithAmount(
        _sAsset,
        _stableAsset,
        _slippage,
        assetLiquidationThreshold,
        _principal
      );
      return;
    }

    uint256 count;
    do {
      // limit loop count
      require(count < _iterations, Errors.LS_REMOVE_ITERATION_OVER);

      // withdraw collateral keeping the normal healthFactor (T / LTV)
      uint256 availableAmount = _getWithdrawalAmount(
        _sAsset,
        msg.sender,
        assetLiquidationThreshold,
        normalHealthFactor
      );
      if (availableAmount == 0) break;

      uint256 requiredAmount = _principal - IERC20(COLLATERAL).balanceOf(address(this));
      uint256 removeAmount = Math.min(availableAmount, requiredAmount);
      IERC20(_sAsset).safeTransferFrom(msg.sender, address(this), removeAmount);
      _remove(removeAmount, _slippage);

      if (removeAmount == requiredAmount) break;

      uint256 debtAmount = _getDebtAmount(variableDebtTokenAddress, msg.sender);
      if (debtAmount > 0) {
        // swap collateral to stable coin
        // in this case, some collateral asset maybe remained because of convex (ex: sUSD)
        uint256 stableAssetAmount = _swapFrom(_stableAsset);
        uint256 repayAmount = Math.min(debtAmount, stableAssetAmount);
        // repay
        _repay(_stableAsset, repayAmount, msg.sender);
        if (stableAssetAmount > repayAmount) {
          // swap stable coin to collateral in case of extra ramined stable coin after repay
          _swapTo(_stableAsset, stableAssetAmount - repayAmount);
        }
      }

      count++;
    } while (true);

    // finally deliver the collateral to user
    IERC20(COLLATERAL).safeTransfer(msg.sender, IERC20(COLLATERAL).balanceOf(address(this)));

    emit LeavePosition(_principal, _stableAsset);
  }

  /**
   * @param _repayAmount - The amount of repay
   * @param _requiredAmount - The amount of collateral
   * @param _slippage1 - Slippage valule to borrow enough asset by flashloan,
   *                    Must be greater than 0%.
   * @param _slippage2 - The slippage of the every withdrawal amount. 1% = 100
   * @param _stableAsset - The borrowing stable coin address when leverage works
   * @param _sAsset - staked asset address of collateral internal asset
   */
  function withdrawWithFlashloan(
    uint256 _repayAmount,
    uint256 _requiredAmount,
    uint256 _slippage1,
    uint256 _slippage2,
    address _stableAsset,
    address _sAsset
  ) external {
    require(_repayAmount > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_requiredAmount > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_slippage1 > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_slippage2 > 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(ENABLED_STABLE_COINS[_stableAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(_sAsset != address(0), Errors.LS_INVALID_CONFIGURATION);

    IAaveFlashLoan AAVE_LENDING_POOL = IAaveFlashLoan(AAVE_LENDING_POOL_ADDRESS);
    address[] memory assets = new address[](1);
    assets[0] = _stableAsset;

    uint256 debtAmount = _getDebtAmount(
      LENDING_POOL.getReserveData(_stableAsset).variableDebtTokenAddress,
      msg.sender
    );

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = Math.min(_repayAmount, debtAmount);

    // 0 means revert the transaction if not validated
    uint256[] memory modes = new uint256[](1);
    modes[0] = 0;

    bytes memory params = abi.encode(
      false, /*leavePosition*/
      _slippage2,
      _requiredAmount,
      msg.sender,
      _sAsset
    );

    AAVE_LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
    // remained stable coin -> collateral
    _swapTo(_stableAsset, IERC20(_stableAsset).balanceOf(address(this)));

    uint256 collateralAmount = IERC20(COLLATERAL).balanceOf(address(this));
    if (collateralAmount > _requiredAmount) {
      _supply(collateralAmount - _requiredAmount, msg.sender);
      collateralAmount = _requiredAmount;
    }

    // finally deliver the collateral to user
    IERC20(COLLATERAL).safeTransfer(msg.sender, collateralAmount);
  }

  function _enterPositionWithFlashloan(
    uint256 _minAmount,
    address _user,
    address _stableAsset,
    uint256 _borrowedAmount,
    uint256 _fee
  ) internal {
    //swap stable coin to collateral
    uint256 collateralAmount = _swapTo(_stableAsset, _borrowedAmount);
    require(collateralAmount >= _minAmount, Errors.LS_SUPPLY_FAILED);

    //deposit collateral
    _supply(collateralAmount, _user);

    //borrow stable coin
    _borrow(_stableAsset, _borrowedAmount + _fee, _user);
  }

  function _withdrawWithFlashloan(
    uint256 _slippage,
    uint256 _requiredAmount,
    address _user,
    address _sAsset,
    address _stableAsset,
    uint256 _borrowedAmount
  ) internal {
    // repay
    _repay(_stableAsset, _borrowedAmount, _user);

    // withdraw collateral
    // get internal asset address
    address internalAsset = IAToken(_sAsset).UNDERLYING_ASSET_ADDRESS();
    // get reserve info of internal asset
    DataTypes.ReserveConfigurationMap memory configuration = LENDING_POOL.getConfiguration(
      internalAsset
    );
    (, uint256 assetLiquidationThreshold, , , ) = configuration.getParamsMemory();
    require(assetLiquidationThreshold != 0, Errors.LS_INVALID_CONFIGURATION);
    // get user info
    (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      ,
      uint256 currentLiquidationThreshold,
      ,

    ) = LENDING_POOL.getUserAccountData(_user);

    uint256 withdrawalAmountETH = (totalCollateralETH.percentMul(currentLiquidationThreshold) -
      totalDebtETH).percentDiv(assetLiquidationThreshold);

    uint256 withdrawalAmount = Math.min(
      IERC20(_sAsset).balanceOf(_user),
      (withdrawalAmountETH * (10**DECIMALS)) / _getAssetPrice(COLLATERAL)
    );

    require(withdrawalAmount > _requiredAmount, Errors.LS_SUPPLY_NOT_ALLOWED);

    IERC20(_sAsset).safeTransferFrom(_user, address(this), withdrawalAmount);
    _remove(withdrawalAmount, _slippage);

    // collateral -> stable
    _swapFrom(_stableAsset);
  }

  function _reduceLeverageWithAmount(
    address _sAsset,
    address _stableAsset,
    uint256 _slippage,
    uint256 _assetLiquidationThreshold,
    uint256 _amount
  ) internal {
    // withdraw available collateral
    uint256 requireAmount = _amount;
    address variableDebtTokenAddress = LENDING_POOL
      .getReserveData(_stableAsset)
      .variableDebtTokenAddress;

    do {
      uint256 debtAmount = _getDebtAmount(variableDebtTokenAddress, msg.sender);
      if (debtAmount == 0) break;

      uint256 availableAmount = _getWithdrawalAmount(
        _sAsset,
        msg.sender,
        _assetLiquidationThreshold,
        WadRayMath.wad()
      );
      uint256 removeAmount = _amount > 0
        ? Math.min(availableAmount, requireAmount)
        : availableAmount;
      IERC20(_sAsset).safeTransferFrom(msg.sender, address(this), removeAmount);
      _remove(removeAmount, _slippage);

      // swap collateral to stable coin
      // in this case, some collateral asset maybe remained because of convex (ex: sUSD)
      uint256 stableAssetAmount = _swapFrom(_stableAsset);
      uint256 repayAmount = Math.min(debtAmount, stableAssetAmount);
      // repay
      _repay(_stableAsset, repayAmount, msg.sender);
      if (stableAssetAmount > repayAmount) {
        // swap stable coin to collateral in case of extra ramined stable coin after repay
        uint256 collateralAmount = _swapTo(
          _stableAsset,
          IERC20(_stableAsset).balanceOf(address(this))
        );
        _supply(collateralAmount, msg.sender);
        removeAmount -= collateralAmount;
      }

      // one time reduce leverage
      if (_amount == 0) break;

      requireAmount -= removeAmount;
      // completed the required amount to reduce leverage
      if (requireAmount == 0) break;
    } while (true);
  }

  function _supply(uint256 _amount, address _user) internal {
    IGeneralVault(VAULT).depositCollateralFrom(COLLATERAL, _amount, _user);
  }

  function _remove(uint256 _amount, uint256 _slippage) internal {
    IGeneralVault(VAULT).withdrawCollateral(COLLATERAL, _amount, _slippage, address(this));
  }

  function _getWithdrawalAmount(
    address _sAsset,
    address _user,
    uint256 assetLiquidationThreshold,
    uint256 healthFactor
  ) internal view returns (uint256) {
    // get user info
    (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      ,
      uint256 currentLiquidationThreshold,
      ,

    ) = LENDING_POOL.getUserAccountData(_user);

    uint256 withdrawalAmountETH = (((totalCollateralETH * currentLiquidationThreshold) /
      PercentageMath.PERCENTAGE_FACTOR -
      totalDebtETH.wadMul(healthFactor)) * PercentageMath.PERCENTAGE_FACTOR) /
      assetLiquidationThreshold;

    return
      Math.min(
        IERC20(_sAsset).balanceOf(_user),
        (withdrawalAmountETH * (10**DECIMALS)) / _getAssetPrice(COLLATERAL)
      );
  }

  function _getDebtAmount(address _variableDebtTokenAddress, address _user)
    internal
    view
    returns (uint256)
  {
    return IERC20(_variableDebtTokenAddress).balanceOf(_user);
  }

  function _borrow(
    address _stableAsset,
    uint256 _amount,
    address borrower
  ) internal {
    LENDING_POOL.borrow(_stableAsset, _amount, USE_VARIABLE_DEBT, 0, borrower);
  }

  function _repay(
    address _stableAsset,
    uint256 _amount,
    address borrower
  ) internal {
    IERC20(_stableAsset).safeApprove(address(LENDING_POOL), 0);
    IERC20(_stableAsset).safeApprove(address(LENDING_POOL), _amount);

    LENDING_POOL.repay(_stableAsset, _amount, USE_VARIABLE_DEBT, borrower);
  }

  function _calcBorrowableAmount(
    uint256 _collateralAmount,
    uint256 _ltv,
    address _borrowAsset,
    uint256 _assetDecimals
  ) internal view returns (uint256) {
    uint256 availableBorrowsETH = (_collateralAmount *
      _getAssetPrice(COLLATERAL).percentMul(_ltv)) / (10**DECIMALS);

    availableBorrowsETH = availableBorrowsETH > SAFE_BUFFER ? availableBorrowsETH - SAFE_BUFFER : 0;

    uint256 availableBorrowsAsset = (availableBorrowsETH * (10**_assetDecimals)) /
      _getAssetPrice(_borrowAsset);

    return availableBorrowsAsset;
  }

  function _swapTo(address, uint256) internal virtual returns (uint256) {
    return 0;
  }

  function _swapFrom(address) internal virtual returns (uint256) {
    return 0;
  }
}