// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './libraries/DataStruct.sol';

import './logic/Index.sol';
import './logic/Rate.sol';
import './logic/Validation.sol';
import './logic/AssetBond.sol';

import './interfaces/ILToken.sol';
import './interfaces/IDToken.sol';
import './interfaces/IMoneyPool.sol';
import './interfaces/IIncentivePool.sol';
import './interfaces/ITokenizer.sol';

import './MoneyPoolStorage.sol';

/**
 * @title Main contract for ELYFI version 1.
 * @author ELYSIA
 * @notice This is the first version of ELYFI. ELYFI has various contract interactions centered
 * on the Money Pool Contract. Several tokens are issued or destroyed to indicate the status of
 * participants, and all issuance and burn processes are carried out through the Money Pool Contract.
 * The depositor and borrower should approve the ELYFI moneypool contract to move their AssetBond token
 * or ERC20 tokens on their behalf.
 * @dev Only admin can modify the variables and state of the moneypool
 **/
contract MoneyPool is IMoneyPool, MoneyPoolStorage {
  using SafeERC20 for IERC20;
  using Index for DataStruct.ReserveData;
  using Validation for DataStruct.ReserveData;
  using Rate for DataStruct.ReserveData;
  using AssetBond for DataStruct.AssetBondData;

  constructor(uint256 maxReserveCount_, address connector) {
    _connector = IConnector(connector);
    _maxReserveCount = maxReserveCount_;
    _reserveCount += 1;
  }

  /************ MoneyPool Deposit Functions ************/

  /**
   * @notice By depositing virtual assets in the MoneyPool and supply liquidity, depositors can receive
   * interest accruing from the MoneyPool.The return on the deposit arises from the interest on real asset
   * backed loans. MoneyPool depositors who deposit certain cryptoassets receives LTokens equivalent to
   * the deposit amount. LTokens are backed by cryptoassets deposited in the MoneyPool in a 1:1 ratio.
   * @dev Deposits an amount of underlying asset and receive corresponding LTokens.
   * @param asset The address of the underlying asset to deposit
   * @param account The address that will receive the LToken
   * @param amount Deposit amount
   **/
  function deposit(
    address asset,
    address account,
    uint256 amount
  ) external override {
    DataStruct.ReserveData storage reserve = _reserves[asset];

    Validation.validateDeposit(reserve, amount);

    reserve.updateState(asset);

    reserve.updateRates(asset, amount, 0);

    IERC20(asset).safeTransferFrom(msg.sender, reserve.lTokenAddress, amount);

    ILToken(reserve.lTokenAddress).mint(account, amount, reserve.lTokenInterestIndex);

    emit Deposit(asset, account, amount);
  }

  /**
   * @notice The depositors can seize their virtual assets deposited in the MoneyPool whenever they wish.
   * @dev Withdraws an amount of underlying asset from the reserve and burns the corresponding lTokens.
   * @param asset The address of the underlying asset to withdraw
   * @param account The address that will receive the underlying asset
   * @param amount Withdrawl amount
   **/
  function withdraw(
    address asset,
    address account,
    uint256 amount
  ) external override {
    DataStruct.ReserveData storage reserve = _reserves[asset];

    uint256 userLTokenBalance = ILToken(reserve.lTokenAddress).balanceOf(msg.sender);

    uint256 amountToWithdraw = amount;

    if (amount == type(uint256).max) {
      amountToWithdraw = userLTokenBalance;
    }

    Validation.validateWithdraw(reserve, asset, amountToWithdraw, userLTokenBalance);

    reserve.updateState(asset);

    reserve.updateRates(asset, 0, amountToWithdraw);

    ILToken(reserve.lTokenAddress).burn(
      msg.sender,
      account,
      amountToWithdraw,
      reserve.lTokenInterestIndex
    );

    emit Withdraw(asset, msg.sender, account, amountToWithdraw);
  }

  /************ AssetBond Formation Functions ************/

  /**
   * @notice The collateral service provider can take out a loan of value equivalent to the principal
   * recorded in the asset bond data. As asset bonds are deposited as collateral in the Money Pool
   * and loans are made, financial services that link real assets and cryptoassets can be achieved.
   * @dev Transfer asset bond from the collateral service provider to the moneypool and mint dTokens
   *  corresponding to principal. After that, transfer the underlying asset
   * @param asset The address of the underlying asset to withdraw
   * @param tokenId The id of the token to collateralize
   **/
  function borrow(address asset, uint256 tokenId) external override {
    require(_connector.isCollateralServiceProvider(msg.sender), 'OnlyCollateralServiceProvider');
    DataStruct.ReserveData storage reserve = _reserves[asset];
    DataStruct.AssetBondData memory assetBond = ITokenizer(reserve.tokenizerAddress)
    .getAssetBondData(tokenId);

    uint256 borrowAmount = assetBond.principal;
    address receiver = assetBond.borrower;

    Validation.validateBorrow(reserve, assetBond, asset, borrowAmount);

    reserve.updateState(asset);

    ITokenizer(reserve.tokenizerAddress).collateralizeAssetBond(
      msg.sender,
      tokenId,
      borrowAmount,
      reserve.borrowAPY
    );

    IDToken(reserve.dTokenAddress).mint(msg.sender, receiver, borrowAmount, reserve.borrowAPY);

    reserve.updateRates(asset, 0, borrowAmount);

    ILToken(reserve.lTokenAddress).transferUnderlyingTo(receiver, borrowAmount);

    emit Borrow(asset, msg.sender, receiver, tokenId, reserve.borrowAPY, borrowAmount);
  }

  /**
   * @notice repays an amount of underlying asset from the reserve and burns the corresponding lTokens.
   * @dev Transfer total repayment of the underlying asset from msg.sender to the moneypool and
   * burn the corresponding amount of dTokens. Then release the asset bond token which is locked
   * in the moneypool and transfer it to the borrower. The total amount of transferred underlying asset
   * is the sum of the fee on the collateral service provider and debt on the moneypool
   * @param asset The address of the underlying asset to repay
   * @param tokenId The id of the token to retrieve
   **/
  function repay(address asset, uint256 tokenId) external override {
    DataStruct.ReserveData storage reserve = _reserves[asset];
    DataStruct.AssetBondData memory assetBond = ITokenizer(reserve.tokenizerAddress)
    .getAssetBondData(tokenId);

    Validation.validateRepay(reserve, assetBond);

    (uint256 accruedDebtOnMoneyPool, uint256 feeOnCollateralServiceProvider) = assetBond
    .getAssetBondDebtData();

    uint256 totalRetrieveAmount = accruedDebtOnMoneyPool + feeOnCollateralServiceProvider;

    reserve.updateState(asset);

    IERC20(asset).safeTransferFrom(msg.sender, reserve.lTokenAddress, totalRetrieveAmount);

    IDToken(reserve.dTokenAddress).burn(assetBond.borrower, accruedDebtOnMoneyPool);

    reserve.updateRates(asset, totalRetrieveAmount, 0);

    ITokenizer(reserve.tokenizerAddress).releaseAssetBond(assetBond.borrower, tokenId);

    ILToken(reserve.lTokenAddress).mint(
      assetBond.collateralServiceProvider,
      feeOnCollateralServiceProvider,
      reserve.lTokenInterestIndex
    );

    emit Repay(
      asset,
      assetBond.borrower,
      tokenId,
      accruedDebtOnMoneyPool,
      feeOnCollateralServiceProvider
    );
  }

  function liquidate(address asset, uint256 tokenId) external override {
    require(_connector.isCollateralServiceProvider(msg.sender), 'OnlyCollateralServiceProvider');
    DataStruct.ReserveData storage reserve = _reserves[asset];
    DataStruct.AssetBondData memory assetBond = ITokenizer(reserve.tokenizerAddress)
    .getAssetBondData(tokenId);

    Validation.validateLiquidation(reserve, assetBond);

    (uint256 accruedDebtOnMoneyPool, uint256 feeOnCollateralServiceProvider) = assetBond
    .getAssetBondLiquidationData();

    uint256 totalLiquidationAmount = accruedDebtOnMoneyPool + feeOnCollateralServiceProvider;

    reserve.updateState(asset);

    IDToken(reserve.dTokenAddress).burn(assetBond.borrower, accruedDebtOnMoneyPool);

    reserve.updateRates(asset, totalLiquidationAmount, 0);

    IERC20(asset).safeTransferFrom(msg.sender, reserve.lTokenAddress, totalLiquidationAmount);

    ITokenizer(reserve.tokenizerAddress).liquidateAssetBond(msg.sender, tokenId);

    ILToken(reserve.lTokenAddress).mint(
      assetBond.collateralServiceProvider,
      feeOnCollateralServiceProvider,
      reserve.lTokenInterestIndex
    );

    emit Liquidation(
      asset,
      assetBond.borrower,
      tokenId,
      accruedDebtOnMoneyPool,
      feeOnCollateralServiceProvider
    );
  }

  /************ View Functions ************/

  /**
   * @notice LToken Index is an indicator of interest occurring and accrued to liquidity providers
   * who have provided liquidity to the Money Pool. LToken Index is calculated every time user activities
   * occur in the Money Pool, such as loans and repayments by Money Pool participants.
   * @param asset The address of the underlying asset of the reserve
   * @return The LToken interest index of reserve
   */
  function getLTokenInterestIndex(address asset) external view override returns (uint256) {
    return _reserves[asset].getLTokenInterestIndex();
  }

  /**
   * @dev Returns the reserveData struct of underlying asset
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    override
    returns (DataStruct.ReserveData memory)
  {
    return _reserves[asset];
  }

  /************ Configuration Functions ************/

  function addNewReserve(
    address asset,
    address lToken,
    address dToken,
    address interestModel,
    address tokenizer,
    address incentivePool,
    uint256 moneyPoolFactor_
  ) external override onlyMoneyPoolAdmin {
    DataStruct.ReserveData memory newReserveData = DataStruct.ReserveData({
      moneyPoolFactor: moneyPoolFactor_,
      lTokenInterestIndex: WadRayMath.ray(),
      borrowAPY: 0,
      depositAPY: 0,
      lastUpdateTimestamp: block.timestamp,
      lTokenAddress: lToken,
      dTokenAddress: dToken,
      interestModelAddress: interestModel,
      tokenizerAddress: tokenizer,
      id: 0,
      isPaused: false,
      isActivated: true
    });

    _reserves[asset] = newReserveData;
    _addNewReserveToList(asset);

    IIncentivePool(incentivePool).initializeIncentivePool(lToken);

    emit NewReserve(
      asset,
      lToken,
      dToken,
      interestModel,
      tokenizer,
      incentivePool,
      moneyPoolFactor_
    );
  }

  function _addNewReserveToList(address asset) internal {
    uint256 reserveCount = _reserveCount;

    require(reserveCount < _maxReserveCount, 'MaxReserveCountExceeded');

    require(_reserves[asset].id == 0, 'DigitalAssetAlreadyAdded');

    _reserves[asset].id = uint8(reserveCount);
    _reservesList[reserveCount] = asset;

    _reserveCount = reserveCount + 1;
  }

  function deactivateMoneyPool(address asset) external onlyMoneyPoolAdmin {
    _reserves[asset].isActivated = false;
  }

  function activateMoneyPool(address asset) external onlyMoneyPoolAdmin {
    _reserves[asset].isActivated = true;
  }

  function pauseMoneyPool(address asset) external onlyMoneyPoolAdmin {
    _reserves[asset].isPaused = true;
  }

  function unPauseMoneyPool(address asset) external onlyMoneyPoolAdmin {
    _reserves[asset].isPaused = false;
  }

  function updateIncentivePool(address asset, address newIncentivePool)
    external
    onlyMoneyPoolAdmin
  {
    DataStruct.ReserveData storage reserve = _reserves[asset];
    ILToken(reserve.lTokenAddress).updateIncentivePool(newIncentivePool);
  }

  modifier onlyMoneyPoolAdmin {
    require(_connector.isMoneyPoolAdmin(msg.sender), 'OnlyMoneyPoolAdmin');
    _;
  }
}