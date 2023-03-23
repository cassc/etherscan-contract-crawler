// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {ReentrancyGuard} from '../../dependencies/openzeppelin/contracts/ReentrancyGuard.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {IGeneralVault} from '../../interfaces/IGeneralVault.sol';
import {IAToken} from '../../interfaces/IAToken.sol';
import {IFlashLoanReceiver} from '../../flashloan/interfaces/IFlashLoanReceiver.sol';
import {IFlashLoanRecipient} from '../../flashloan/interfaces/IFlashLoanRecipient.sol';
import {IVaultWhitelist} from '../../interfaces/IVaultWhitelist.sol';
import {IAaveFlashLoan} from '../../interfaces/IAaveFlashLoan.sol';
import {IBalancerVault} from '../../interfaces/IBalancerVault.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {Math} from '../../dependencies/openzeppelin/contracts/Math.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';

abstract contract GeneralLevSwap is IFlashLoanReceiver, IFlashLoanRecipient, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using WadRayMath for uint256;

  enum FlashLoanType {
    AAVE,
    BALANCER
  }

  uint256 private constant USE_VARIABLE_DEBT = 2;

  address private constant AAVE_LENDING_POOL_ADDRESS = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

  address private constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

  IVaultWhitelist private constant VAULT_WHITELIST =
    IVaultWhitelist(0x88eE44794bAf865E3b0b192d1F9f0AC3Daf1EA0E);

  address public immutable COLLATERAL; // The address of external asset

  uint256 public immutable DECIMALS; // The collateral decimals

  address public immutable VAULT; // The address of vault

  ILendingPoolAddressesProvider internal immutable PROVIDER;

  IPriceOracleGetter internal immutable ORACLE;

  ILendingPool internal immutable LENDING_POOL;

  mapping(address => bool) internal ENABLED_STABLE_COINS;

  //1 == not inExec
  //2 == inExec;
  //setting default to 1 to save some gas.
  uint256 private _balancerFlashLoanLock = 1;

  /**
   * @param _asset The external asset ex. wFTM
   * @param _vault The deployed vault address
   * @param _provider The deployed AddressProvider
   */
  constructor(address _asset, address _vault, address _provider) {
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
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    require(initiator == address(this), Errors.LS_INVALID_CONFIGURATION);
    require(msg.sender == AAVE_LENDING_POOL_ADDRESS, Errors.LS_INVALID_CONFIGURATION);
    require(assets.length == amounts.length, Errors.LS_INVALID_CONFIGURATION);
    require(assets.length == premiums.length, Errors.LS_INVALID_CONFIGURATION);
    require(amounts[0] != 0, Errors.LS_INVALID_CONFIGURATION);
    require(assets[0] != address(0), Errors.LS_INVALID_CONFIGURATION);

    _executeOperation(assets[0], amounts[0], premiums[0], params);

    // approve the Aave LendingPool contract allowance to *pull* the owed amount
    IERC20(assets[0]).safeApprove(AAVE_LENDING_POOL_ADDRESS, 0);
    IERC20(assets[0]).safeApprove(AAVE_LENDING_POOL_ADDRESS, amounts[0] + premiums[0]);

    return true;
  }

  /**
   * This function is called after your contract has received the flash loaned amount
   * overriding receiveFlashLoan() in IFlashLoanRecipient
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external override {
    require(msg.sender == BALANCER_VAULT, Errors.LS_INVALID_CONFIGURATION);
    require(_balancerFlashLoanLock == 2, Errors.LS_INVALID_CONFIGURATION);
    require(tokens.length == amounts.length, Errors.LS_INVALID_CONFIGURATION);
    require(tokens.length == feeAmounts.length, Errors.LS_INVALID_CONFIGURATION);
    require(amounts[0] != 0, Errors.LS_INVALID_CONFIGURATION);
    require(address(tokens[0]) != address(0), Errors.LS_INVALID_CONFIGURATION);
    _balancerFlashLoanLock = 1;

    _executeOperation(address(tokens[0]), amounts[0], feeAmounts[0], userData);

    // send tokens to Balancer vault contract
    IERC20(tokens[0]).safeTransfer(msg.sender, amounts[0] + feeAmounts[0]);
  }

  function _executeOperation(
    address asset,
    uint256 borrowAmount,
    uint256 fee,
    bytes memory params
  ) internal {
    // parse params
    (bool isEnterPosition, uint256 slippage, uint256 amount, address user, address sAsset) = abi
      .decode(params, (bool, uint256, uint256, address, address));
    require(slippage != 0, Errors.LS_INVALID_CONFIGURATION);
    require(amount != 0, Errors.LS_INVALID_CONFIGURATION);
    require(user != address(0), Errors.LS_INVALID_CONFIGURATION);
    if (isEnterPosition) {
      _enterPositionWithFlashloan(slippage, amount, user, asset, borrowAmount, fee);
    } else {
      require(sAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
      _withdrawWithFlashloan(slippage, amount, user, sAsset, asset, borrowAmount);
    }
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
    address _stableAsset,
    FlashLoanType _flashLoanType
  ) external nonReentrant {
    require(_principal != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_leverage != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_slippage != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_leverage < 900_00, Errors.LS_INVALID_CONFIGURATION);
    require(_stableAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
    require(ENABLED_STABLE_COINS[_stableAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(IERC20(COLLATERAL).balanceOf(msg.sender) >= _principal, Errors.LS_SUPPLY_NOT_ALLOWED);

    IERC20(COLLATERAL).safeTransferFrom(msg.sender, address(this), _principal);

    _leverageWithFlashloan(
      msg.sender,
      _principal,
      _leverage,
      _slippage,
      _stableAsset,
      _flashLoanType
    );
  }

  /**
   * @param _repayAmount - The amount of repay
   * @param _requiredAmount - The amount of collateral
   * @param _slippage - The slippage of the every withdrawal amount. 1% = 100
   * @param _stableAsset - The borrowing stable coin address when leverage works
   * @param _sAsset - staked asset address of collateral internal asset
   */
  function withdrawWithFlashloan(
    uint256 _repayAmount,
    uint256 _requiredAmount,
    uint256 _slippage,
    address _stableAsset,
    address _sAsset,
    FlashLoanType _flashLoanType
  ) external nonReentrant {
    require(_repayAmount != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_requiredAmount != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_slippage != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_stableAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
    require(ENABLED_STABLE_COINS[_stableAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(_sAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
    require(
      _sAsset ==
        LENDING_POOL.getReserveData(IAToken(_sAsset).UNDERLYING_ASSET_ADDRESS()).aTokenAddress,
      Errors.LS_INVALID_CONFIGURATION
    );

    uint256 debtAmount = _getDebtAmount(
      LENDING_POOL.getReserveData(_stableAsset).variableDebtTokenAddress,
      msg.sender
    );

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = Math.min(_repayAmount, debtAmount);

    bytes memory params = abi.encode(
      false /*leavePosition*/,
      _slippage,
      _requiredAmount,
      msg.sender,
      _sAsset
    );

    if (_flashLoanType == FlashLoanType.AAVE) {
      // 0 means revert the transaction if not validated
      uint256[] memory modes = new uint256[](1);
      modes[0] = 0;

      address[] memory assets = new address[](1);
      assets[0] = _stableAsset;
      IAaveFlashLoan(AAVE_LENDING_POOL_ADDRESS).flashLoan(
        address(this),
        assets,
        amounts,
        modes,
        address(this),
        params,
        0
      );
    } else {
      require(_balancerFlashLoanLock == 1, Errors.LS_INVALID_CONFIGURATION);
      IERC20[] memory assets = new IERC20[](1);
      assets[0] = IERC20(_stableAsset);
      _balancerFlashLoanLock = 2;
      IBalancerVault(BALANCER_VAULT).flashLoan(address(this), assets, amounts, params);
    }

    // remained stable coin -> collateral
    _swapTo(_stableAsset, IERC20(_stableAsset).balanceOf(address(this)), _slippage);

    uint256 collateralAmount = IERC20(COLLATERAL).balanceOf(address(this));
    if (collateralAmount > _requiredAmount) {
      _supply(collateralAmount - _requiredAmount, msg.sender);
      collateralAmount = _requiredAmount;
    }

    // finally deliver the collateral to user
    IERC20(COLLATERAL).safeTransfer(msg.sender, collateralAmount);
  }

  function _enterPositionWithFlashloan(
    uint256 _slippage,
    uint256 _minAmount,
    address _user,
    address _stableAsset,
    uint256 _borrowedAmount,
    uint256 _fee
  ) internal {
    //swap stable coin to collateral
    uint256 collateralAmount = _swapTo(_stableAsset, _borrowedAmount, _slippage);
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

    uint256 withdrawalAmountETH = (((totalCollateralETH * currentLiquidationThreshold) /
      PercentageMath.PERCENTAGE_FACTOR -
      totalDebtETH) * PercentageMath.PERCENTAGE_FACTOR) / assetLiquidationThreshold;

    uint256 withdrawalAmount = Math.min(
      IERC20(_sAsset).balanceOf(_user),
      (withdrawalAmountETH * (10 ** DECIMALS)) / _getAssetPrice(COLLATERAL)
    );

    require(withdrawalAmount >= _requiredAmount, Errors.LS_SUPPLY_NOT_ALLOWED);

    IERC20(_sAsset).safeTransferFrom(_user, address(this), withdrawalAmount);
    _remove(withdrawalAmount, _slippage, _user);

    // collateral -> stable
    _swapFrom(_stableAsset, _slippage);
  }

  function _supply(uint256 _amount, address _user) internal {
    // whitelist checking
    if (VAULT_WHITELIST.whitelistUserCount(VAULT) != 0) {
      require(VAULT_WHITELIST.whitelistUser(VAULT, _user), Errors.CALLER_NOT_WHITELIST_USER);
    }

    IERC20(COLLATERAL).safeApprove(VAULT, 0);
    IERC20(COLLATERAL).safeApprove(VAULT, _amount);
    IGeneralVault(VAULT).depositCollateralFrom(COLLATERAL, _amount, _user);
  }

  function _remove(uint256 _amount, uint256 _slippage, address _user) internal {
    // whitelist checking
    if (VAULT_WHITELIST.whitelistUserCount(VAULT) != 0) {
      require(VAULT_WHITELIST.whitelistUser(VAULT, _user), Errors.CALLER_NOT_WHITELIST_USER);
    }

    IGeneralVault(VAULT).withdrawCollateral(COLLATERAL, _amount, _slippage, address(this));
  }

  function _getDebtAmount(
    address _variableDebtTokenAddress,
    address _user
  ) internal view returns (uint256) {
    return IERC20(_variableDebtTokenAddress).balanceOf(_user);
  }

  function _borrow(address _stableAsset, uint256 _amount, address borrower) internal {
    LENDING_POOL.borrow(_stableAsset, _amount, USE_VARIABLE_DEBT, 0, borrower);
  }

  function _repay(address _stableAsset, uint256 _amount, address borrower) internal {
    IERC20(_stableAsset).safeApprove(address(LENDING_POOL), 0);
    IERC20(_stableAsset).safeApprove(address(LENDING_POOL), _amount);

    uint256 paybackAmount = LENDING_POOL.repay(_stableAsset, _amount, USE_VARIABLE_DEBT, borrower);
    require(paybackAmount != 0, Errors.LS_REPAY_FAILED);
  }

  function _swapTo(address, uint256, uint256) internal virtual returns (uint256);

  function _swapFrom(address, uint256) internal virtual returns (uint256);

  /**
   * @param _zappingAsset - The stable coin address which will zap into lp token
   * @param _principal - The amount of collateral
   * @param _slippage - Slippage value to zap deposit, Must be greater than 0%.
   */
  function zapDeposit(
    address _zappingAsset,
    uint256 _principal,
    uint256 _slippage
  ) external nonReentrant {
    require(_principal != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_zappingAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
    require(ENABLED_STABLE_COINS[_zappingAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(
      IERC20(_zappingAsset).balanceOf(msg.sender) >= _principal,
      Errors.LS_SUPPLY_NOT_ALLOWED
    );

    IERC20(_zappingAsset).safeTransferFrom(msg.sender, address(this), _principal);

    uint256 suppliedAmount = _swapTo(_zappingAsset, _principal, _slippage);
    // supply to LP
    _supply(suppliedAmount, msg.sender);
  }

  /**
   * @param _zappingAsset - The stable coin address which will zap into lp token
   * @param _principal - The amount of the stable coin
   * @param _leverage - Extra leverage value and must be greater than 0, ex. 300% = 300_00
   *                    principal + principal * leverage should be used as collateral
   * @param _slippage - Slippage valule to borrow enough asset by flashloan,
   *                    Must be greater than 0%.
   *                    Borrowing amount = principal * leverage * slippage
   * @param _borrowAsset - The borrowing stable coin address when leverage works
   */
  function zapLeverageWithFlashloan(
    address _zappingAsset,
    uint256 _principal,
    uint256 _leverage,
    uint256 _slippage,
    address _borrowAsset,
    FlashLoanType _flashLoanType
  ) external nonReentrant {
    require(_principal != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_leverage != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_slippage != 0, Errors.LS_SWAP_AMOUNT_NOT_GT_0);
    require(_leverage < 900_00, Errors.LS_INVALID_CONFIGURATION);
    require(_borrowAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
    require(_zappingAsset != address(0), Errors.LS_INVALID_CONFIGURATION);
    require(ENABLED_STABLE_COINS[_zappingAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(ENABLED_STABLE_COINS[_borrowAsset], Errors.LS_STABLE_COIN_NOT_SUPPORTED);
    require(
      IERC20(_zappingAsset).balanceOf(msg.sender) >= _principal,
      Errors.LS_SUPPLY_NOT_ALLOWED
    );

    IERC20(_zappingAsset).safeTransferFrom(msg.sender, address(this), _principal);

    uint256 collateralAmount = _swapTo(_zappingAsset, _principal, _slippage);

    _leverageWithFlashloan(
      msg.sender,
      collateralAmount,
      _leverage,
      _slippage,
      _borrowAsset,
      _flashLoanType
    );
  }

  function _leverageWithFlashloan(
    address _user,
    uint256 _principal,
    uint256 _leverage,
    uint256 _slippage,
    address _borrowAsset,
    FlashLoanType _flashLoanType
  ) internal {
    uint256 borrowAssetDecimals = IERC20Detailed(_borrowAsset).decimals();

    uint256[] memory amounts = new uint256[](1);
    amounts[0] = ((((_principal * _getAssetPrice(COLLATERAL)) / 10 ** DECIMALS) *
      10 ** borrowAssetDecimals) / _getAssetPrice(_borrowAsset)).percentMul(_leverage).percentMul(
        PercentageMath.PERCENTAGE_FACTOR + _slippage
      );

    uint256 minCollateralAmount = _principal.percentMul(
      PercentageMath.PERCENTAGE_FACTOR + _leverage
    );
    bytes memory params = abi.encode(
      true /*enterPosition*/,
      _slippage,
      minCollateralAmount,
      _user,
      address(0)
    );

    if (_flashLoanType == FlashLoanType.AAVE) {
      // 0 means revert the transaction if not validated
      uint256[] memory modes = new uint256[](1);
      modes[0] = 0;

      address[] memory assets = new address[](1);
      assets[0] = _borrowAsset;
      IAaveFlashLoan(AAVE_LENDING_POOL_ADDRESS).flashLoan(
        address(this),
        assets,
        amounts,
        modes,
        address(this),
        params,
        0
      );
    } else {
      require(_balancerFlashLoanLock == 1, Errors.LS_INVALID_CONFIGURATION);
      IERC20[] memory assets = new IERC20[](1);
      assets[0] = IERC20(_borrowAsset);
      _balancerFlashLoanLock = 2;
      IBalancerVault(BALANCER_VAULT).flashLoan(address(this), assets, amounts, params);
      _balancerFlashLoanLock = 1;
    }
  }

  function _getMinAmount(
    address _assetToSwapFrom,
    address _assetToSwapTo,
    uint256 _amountToSwap,
    uint256 _slippage
  ) internal view returns (uint256) {
    uint256 fromAssetDecimals = IERC20Detailed(_assetToSwapFrom).decimals();
    uint256 toAssetDecimals = IERC20Detailed(_assetToSwapTo).decimals();

    uint256 fromAssetPrice = _getAssetPrice(_assetToSwapFrom);
    uint256 toAssetPrice = _getAssetPrice(_assetToSwapTo);

    return
      ((_amountToSwap * fromAssetPrice * 10 ** toAssetDecimals) /
        (toAssetPrice * 10 ** fromAssetDecimals)).percentMul(
          PercentageMath.PERCENTAGE_FACTOR - _slippage
        );
  }
}