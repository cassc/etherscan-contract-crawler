// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  ILendingManager
} from '../../lending-module/interfaces/ILendingManager.sol';
import {
  ILendingStorageManager
} from '../../lending-module/interfaces/ILendingStorageManager.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from './interfaces/IMultiLpLiquidityPool.sol';
import {
  ISynthereumMultiLpLiquidityPoolEvents
} from './interfaces/IMultiLpLiquidityPoolEvents.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ExplicitERC20} from '../../base/utils/ExplicitERC20.sol';

/**
 * @title Multi LP Synthereum pool lib containing internal logic
 */

library SynthereumMultiLpLiquidityPoolLib {
  using PreciseUnitMath for uint256;
  using SafeERC20 for IStandardERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using ExplicitERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct PositionCache {
    // Address of the LP
    address lp;
    // Position of the LP
    ISynthereumMultiLpLiquidityPool.LPPosition lpPosition;
  }

  struct TempStorageArgs {
    uint256 price;
    uint256 totalSyntheticAsset;
    uint8 decimals;
  }

  struct TempInterstArgs {
    uint256 totalCapacity;
    uint256 totalUtilization;
    uint256 capacityShare;
    uint256 utilizationShare;
    uint256 interest;
    uint256 remainingInterest;
    bool isTotCapacityNotZero;
    bool isTotUtilizationNotZero;
  }

  struct TempInterstSharesArgs {
    address lp;
    uint256 capacityShare;
    uint256 utilizationShare;
    BestShare bestShare;
  }

  struct TempSplitOperationArgs {
    ISynthereumMultiLpLiquidityPool.LPPosition lpPosition;
    uint256 remainingTokens;
    uint256 remainingFees;
    uint256 tokens;
    uint256 fees;
    BestShare bestShare;
  }

  struct BestShare {
    uint256 share;
    uint256 index;
  }

  struct LiquidationUpdateArgs {
    address liquidator;
    ILendingManager lendingManager;
    address liquidatedLp;
    uint256 tokensInLiquidation;
    uint256 overCollateralRequirement;
    TempStorageArgs tempStorageArgs;
    PositionCache lpCache;
    address lp;
    uint256 actualCollateralAmount;
    uint256 actualSynthTokens;
    bool isOvercollateralized;
  }

  struct TempMigrationArgs {
    uint256 prevTotalAmount;
    bool isLpGain;
    uint256 globalLpsProfitOrLoss;
    uint256 actualLpsCollateral;
    uint256 share;
    uint256 shareAmount;
    uint256 remainingAmount;
    uint256 lpNumbers;
    bool isOvercollateralized;
  }

  struct WithdrawDust {
    bool isPositive;
    uint256 amount;
  }

  // See IMultiLpLiquidityPoolEvents for events description
  event SetFeePercentage(uint256 newFee);

  event SetLiquidationReward(uint256 newLiquidationReward);

  event NewLendingModule(string lendingModuleId);

  /**
   * @notice Update collateral amount of every LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _updateActualLPCollateral(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache
  ) internal {
    PositionCache memory lpCache;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      _storageParams.lpPositions[lpCache.lp].actualCollateralAmount = lpCache
        .lpPosition
        .actualCollateralAmount;
    }
  }

  /**
   * @notice Update collateral amount of every LP and add the new deposit for one LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _depositingLp Address of the LP depositing collateral
   * @param _increaseCollateral Amount of collateral to increase to the LP
   * @return newLpCollateralAmount Amount of collateral of the LP after the increase
   */
  function _updateAndIncreaseActualLPCollateral(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache,
    address _depositingLp,
    uint256 _increaseCollateral
  ) internal returns (uint256 newLpCollateralAmount) {
    PositionCache memory lpCache;
    address lp;
    uint256 actualCollateralAmount;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lp = lpCache.lp;
      actualCollateralAmount = lpCache.lpPosition.actualCollateralAmount;
      if (lp == _depositingLp) {
        newLpCollateralAmount = actualCollateralAmount + _increaseCollateral;
        _storageParams.lpPositions[lp]
          .actualCollateralAmount = newLpCollateralAmount;
      } else {
        _storageParams.lpPositions[lp]
          .actualCollateralAmount = actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Update collateral amount of every LP and removw withdrawal for one LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _withdrawingLp Address of the LP withdrawing collateral
   * @param _decreaseCollateral Amount of collateral to decrease from the LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return newLpCollateralAmount Amount of collateral of the LP after the decrease
   */
  function _updateAndDecreaseActualLPCollateral(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache,
    address _withdrawingLp,
    uint256 _decreaseCollateral,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal returns (uint256 newLpCollateralAmount) {
    PositionCache memory lpCache;
    address lp;
    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    uint256 actualCollateralAmount;
    bool isOvercollateralized;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lp = lpCache.lp;
      lpPosition = lpCache.lpPosition;
      actualCollateralAmount = lpPosition.actualCollateralAmount;
      if (lp == _withdrawingLp) {
        newLpCollateralAmount = actualCollateralAmount - _decreaseCollateral;
        (isOvercollateralized, ) = _isOvercollateralizedLP(
          newLpCollateralAmount,
          lpPosition.overCollateralization,
          lpPosition.tokensCollateralized,
          _price,
          _collateralDecimals
        );
        require(
          isOvercollateralized,
          'LP below its overcollateralization level'
        );
        _storageParams.lpPositions[lp]
          .actualCollateralAmount = newLpCollateralAmount;
      } else {
        _storageParams.lpPositions[lp]
          .actualCollateralAmount = actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Update collateral amount of every LP and change overcollateralization for one LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _lp Address of the LP changing overcollateralization
   * @param _newOverCollateralization New overcollateralization to be set for the LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   */
  function _updateAndModifyActualLPOverCollateral(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache,
    address _lp,
    uint128 _newOverCollateralization,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal {
    PositionCache memory lpCache;
    address lp;
    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    uint256 actualCollateralAmount;
    bool isOvercollateralized;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lp = lpCache.lp;
      lpPosition = lpCache.lpPosition;
      actualCollateralAmount = lpPosition.actualCollateralAmount;
      if (lp == _lp) {
        (isOvercollateralized, ) = _isOvercollateralizedLP(
          actualCollateralAmount,
          _newOverCollateralization,
          lpPosition.tokensCollateralized,
          _price,
          _collateralDecimals
        );
        require(
          isOvercollateralized,
          'LP below its overcollateralization level'
        );
        _storageParams.lpPositions[lp]
          .actualCollateralAmount = actualCollateralAmount;
        _storageParams.lpPositions[lp]
          .overCollateralization = _newOverCollateralization;
      } else {
        _storageParams.lpPositions[lp]
          .actualCollateralAmount = actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Update collateral amount and synthetic assets of every LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _updateActualLPPositions(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache
  ) internal {
    PositionCache memory lpCache;
    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lpPosition = lpCache.lpPosition;
      _storageParams.lpPositions[lpCache.lp].actualCollateralAmount = lpPosition
        .actualCollateralAmount;
      _storageParams.lpPositions[lpCache.lp].tokensCollateralized = lpPosition
        .tokensCollateralized;
    }
  }

  /**
   * @notice Update collateral amount of every LP and add the new deposit for one LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _liquidatedLp Address of the LP to liquidate
   * @param _tokensInLiquidation Amount of synthetic token to liquidate
   * @param _liquidationUpdateArgs Arguments for update liquidation (see LiquidationUpdateArgs struct)
   * @return tokensToLiquidate Amount of tokens will be liquidated
   * @return collateralAmount Amount of collateral value equivalent to tokens in liquidation
   * @return liquidationBonusAmount Amount of bonus collateral for the liquidation
   * @return collateralReceived Amount of collateral received by the liquidator
   */
  function _updateAndLiquidate(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache,
    address _liquidatedLp,
    uint256 _tokensInLiquidation,
    LiquidationUpdateArgs memory _liquidationUpdateArgs
  )
    internal
    returns (
      uint256 tokensToLiquidate,
      uint256 collateralAmount,
      uint256 liquidationBonusAmount,
      uint256 collateralReceived
    )
  {
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      _liquidationUpdateArgs.lpCache = _positionsCache[j];
      _liquidationUpdateArgs.lp = _liquidationUpdateArgs.lpCache.lp;
      // lpPosition = lpCache.lpPosition;
      _liquidationUpdateArgs.actualCollateralAmount = _liquidationUpdateArgs
        .lpCache
        .lpPosition
        .actualCollateralAmount;
      _liquidationUpdateArgs.actualSynthTokens = _liquidationUpdateArgs
        .lpCache
        .lpPosition
        .tokensCollateralized;

      if (_liquidationUpdateArgs.lp == _liquidatedLp) {
        tokensToLiquidate = PreciseUnitMath.min(
          _tokensInLiquidation,
          _liquidationUpdateArgs.actualSynthTokens
        );
        require(tokensToLiquidate > 0, 'No synthetic tokens to liquidate');

        collateralAmount = _calculateCollateralAmount(
          tokensToLiquidate,
          _liquidationUpdateArgs.tempStorageArgs.price,
          _liquidationUpdateArgs.tempStorageArgs.decimals
        );

        (
          _liquidationUpdateArgs.isOvercollateralized,

        ) = _isOvercollateralizedLP(
          _liquidationUpdateArgs.actualCollateralAmount,
          _liquidationUpdateArgs.overCollateralRequirement,
          _liquidationUpdateArgs.actualSynthTokens,
          _liquidationUpdateArgs.tempStorageArgs.price,
          _liquidationUpdateArgs.tempStorageArgs.decimals
        );
        require(
          !_liquidationUpdateArgs.isOvercollateralized,
          'LP is overcollateralized'
        );

        liquidationBonusAmount = _liquidationUpdateArgs
          .actualCollateralAmount
          .mul(_storageParams.liquidationBonus)
          .mul(tokensToLiquidate.div(_liquidationUpdateArgs.actualSynthTokens));

        (
          ILendingManager.ReturnValues memory lendingValues,
          WithdrawDust memory withdrawDust
        ) =
          _lendingWithdraw(
            _liquidationUpdateArgs.lendingManager,
            _liquidationUpdateArgs.liquidator,
            collateralAmount + liquidationBonusAmount
          );

        liquidationBonusAmount = withdrawDust.isPositive
          ? liquidationBonusAmount - withdrawDust.amount
          : liquidationBonusAmount + withdrawDust.amount;

        collateralReceived = lendingValues.tokensTransferred;

        _storageParams.lpPositions[_liquidatedLp].actualCollateralAmount =
          _liquidationUpdateArgs.actualCollateralAmount -
          liquidationBonusAmount;
        _storageParams.lpPositions[_liquidatedLp].tokensCollateralized =
          _liquidationUpdateArgs.actualSynthTokens -
          tokensToLiquidate;
      } else {
        _storageParams.lpPositions[_liquidationUpdateArgs.lp]
          .actualCollateralAmount = _liquidationUpdateArgs
          .actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Set new liquidation reward percentage
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _newLiquidationReward New liquidation reward percentage
   */
  function _setLiquidationReward(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint64 _newLiquidationReward
  ) internal {
    require(
      _newLiquidationReward > 0 &&
        _newLiquidationReward <= PreciseUnitMath.PRECISE_UNIT,
      'Liquidation reward must be between 0 and 100%'
    );
    _storageParams.liquidationBonus = _newLiquidationReward;
    emit SetLiquidationReward(_newLiquidationReward);
  }

  /**
   * @notice Set new fee percentage
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _newFee New fee percentage
   */
  function _setFee(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint64 _newFee
  ) internal {
    require(
      _newFee < PreciseUnitMath.PRECISE_UNIT,
      'Fee Percentage must be less than 100%'
    );
    _storageParams.fee = _newFee;
    emit SetFeePercentage(_newFee);
  }

  /**
   * @notice Set new lending module name
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lendingModuleId Lending module name
   */
  function _setLendingModule(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    string calldata _lendingModuleId
  ) internal {
    _storageParams.lendingModuleId = _lendingModuleId;
    emit NewLendingModule(_lendingModuleId);
  }

  /**
   * @notice Deposit collateral to the lending manager
   * @param _lendingManager Addres of lendingManager
   * @param _sender User/LP depositing
   * @param _collateralAsset Collateral token of the pool
   * @param _collateralAmount Amount of collateral to deposit
   * @return Return values parameters from lending manager
   */
  function _lendingDeposit(
    ILendingManager _lendingManager,
    address _sender,
    IStandardERC20 _collateralAsset,
    uint256 _collateralAmount
  ) internal returns (ILendingManager.ReturnValues memory) {
    _collateralAsset.safeTransferFrom(
      _sender,
      address(_lendingManager),
      _collateralAmount
    );

    return _lendingManager.deposit(_collateralAmount);
  }

  /**
   * @notice Withdraw collateral from the lending manager
   * @param _lendingManager Addres of lendingManager
   * @param _recipient Recipient to which collateral is sent
   * @param _collateralAmount Collateral to withdraw
   * @return Return values parameters from lending manager
   * @return Dust to add/decrease if transfer of bearing token from pool to lending manager is not exact
   */
  function _lendingWithdraw(
    ILendingManager _lendingManager,
    address _recipient,
    uint256 _collateralAmount
  )
    internal
    returns (ILendingManager.ReturnValues memory, WithdrawDust memory)
  {
    (uint256 bearingAmount, address bearingToken) =
      _lendingManager.collateralToInterestToken(
        address(this),
        _collateralAmount
      );

    (uint256 amountTransferred, ) =
      IERC20(bearingToken).explicitSafeTransfer(
        address(_lendingManager),
        bearingAmount
      );

    ILendingManager.ReturnValues memory returnValues =
      _lendingManager.withdraw(amountTransferred, _recipient);

    bool isPositiveDust = _collateralAmount >= returnValues.tokensOut;

    return (
      returnValues,
      WithdrawDust(
        isPositiveDust,
        isPositiveDust
          ? _collateralAmount - returnValues.tokensOut
          : returnValues.tokensOut - _collateralAmount
      )
    );
  }

  /**
   * @notice Migrate lending module protocol
   * @param _lendingManager Addres of lendingManager
   * @param _lendingStorageManager Addres of lendingStoarageManager
   * @param  _lendingId Name of the new lending protocol to migrate to
   * @param  _bearingToken Bearing token of the new lending protocol to switch (only if requetsed by the protocol)
   * @return Return migration values parameters from lending manager
   */
  function _lendingMigration(
    ILendingManager _lendingManager,
    ILendingStorageManager _lendingStorageManager,
    string calldata _lendingId,
    address _bearingToken
  ) internal returns (ILendingManager.MigrateReturnValues memory) {
    IERC20 actualBearingToken =
      IERC20(_lendingStorageManager.getInterestBearingToken(address(this)));
    uint256 actualBearingAmount = actualBearingToken.balanceOf(address(this));
    (uint256 amountTransferred, ) =
      actualBearingToken.explicitSafeTransfer(
        address(_lendingManager),
        actualBearingAmount
      );
    return
      _lendingManager.migrateLendingModule(
        _lendingId,
        _bearingToken,
        amountTransferred
      );
  }

  /**
   * @notice Pulls and burns synthetic tokens from the sender
   * @param _syntheticAsset Synthetic asset of the pool
   * @param _numTokens The number of tokens to be burned
   * @param _sender Sender of synthetic tokens
   */
  function _burnSyntheticTokens(
    IMintableBurnableERC20 _syntheticAsset,
    uint256 _numTokens,
    address _sender
  ) internal {
    // Transfer synthetic token from the user to the pool
    _syntheticAsset.safeTransferFrom(_sender, address(this), _numTokens);

    // Burn synthetic asset
    _syntheticAsset.burn(_numTokens);
  }

  /**
   * @notice Save LP positions in the cache
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @return totalLPsCollateral Sum of all the LP's collaterals
   * @return mostFundedIndex Index in the positionsCache of the LP collateralizing more money
   */
  function _loadPositions(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    PositionCache[] memory _positionsCache
  )
    internal
    view
    returns (uint256 totalLPsCollateral, uint256 mostFundedIndex)
  {
    address lp;
    uint256 maxTokensHeld;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lp = _storageParams.activeLPs.at(j);
      ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition =
        _storageParams.lpPositions[lp];
      _positionsCache[j] = PositionCache(lp, lpPosition);
      totalLPsCollateral += lpPosition.actualCollateralAmount;
      bool isLessFunded = lpPosition.tokensCollateralized <= maxTokensHeld;
      mostFundedIndex = isLessFunded ? mostFundedIndex : j;
      maxTokensHeld = isLessFunded
        ? maxTokensHeld
        : lpPosition.tokensCollateralized;
    }
  }

  /**
   * @notice Calculate new positons from previous interaction
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _totalInterests Amount of interests to split between active LPs
   * @param _price Actual price of the pair
   * @param _totalSynthTokens Amount of synthetic asset collateralized by the pool
   * @param _prevTotalCollateral Total amount in the pool before the operation
   * @param _collateralDecimals Decimals of the collateral token
   * @return positionsCache Temporary memory cache containing LPs positions
   * @return prevTotalLPsCollateral Sum of all the LP's collaterals before interests and P&L are charged
   * @return mostFundedIndex Index of the LP with biggest amount of synt tokens held in his position
   */
  function _calculateNewPositions(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _totalInterests,
    uint256 _price,
    uint256 _totalSynthTokens,
    uint256 _prevTotalCollateral,
    uint8 _collateralDecimals
  )
    internal
    view
    returns (
      PositionCache[] memory positionsCache,
      uint256 prevTotalLPsCollateral,
      uint256 mostFundedIndex
    )
  {
    uint256 lpNumbers = _storageParams.activeLPs.length();

    if (lpNumbers > 0) {
      positionsCache = new PositionCache[](lpNumbers);

      (prevTotalLPsCollateral, mostFundedIndex) = _calculateInterest(
        _storageParams,
        _totalInterests,
        _price,
        _collateralDecimals,
        positionsCache
      );

      _calculateProfitAndLoss(
        _price,
        _totalSynthTokens,
        _prevTotalCollateral - prevTotalLPsCollateral,
        _collateralDecimals,
        positionsCache,
        mostFundedIndex
      );
    }
  }

  /**
   * @notice Calculate interests of each Lp
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _totalInterests Amount of interests to split between active LPs
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @return prevTotalLPsCollateral Sum of all the LP's collaterals before interests are charged
   * @return mostFundedIndex Index in the positionsCache of the LP collateralizing more money
   */
  function _calculateInterest(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _totalInterests,
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache
  )
    internal
    view
    returns (uint256 prevTotalLPsCollateral, uint256 mostFundedIndex)
  {
    uint256 lpNumbers = _positionsCache.length;
    TempInterstArgs memory tempInterstArguments;
    uint256[] memory capacityShares = new uint256[](_positionsCache.length);
    uint256[] memory utilizationShares = new uint256[](_positionsCache.length);

    (
      tempInterstArguments.totalCapacity,
      tempInterstArguments.totalUtilization,
      prevTotalLPsCollateral,
      mostFundedIndex
    ) = _calculateInterestShares(
      _storageParams,
      _price,
      _collateralDecimals,
      _positionsCache,
      capacityShares,
      utilizationShares
    );

    tempInterstArguments.isTotCapacityNotZero =
      tempInterstArguments.totalCapacity > 0;
    tempInterstArguments.isTotUtilizationNotZero =
      tempInterstArguments.totalUtilization > 0;
    require(
      tempInterstArguments.isTotCapacityNotZero ||
        tempInterstArguments.isTotUtilizationNotZero,
      'No capacity and utilization'
    );
    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    tempInterstArguments.remainingInterest = _totalInterests;
    if (
      tempInterstArguments.isTotCapacityNotZero &&
      tempInterstArguments.isTotUtilizationNotZero
    ) {
      for (uint256 j = 0; j < lpNumbers; j++) {
        tempInterstArguments.capacityShare = capacityShares[j].div(
          tempInterstArguments.totalCapacity
        );
        tempInterstArguments.utilizationShare = utilizationShares[j].div(
          tempInterstArguments.totalUtilization
        );
        tempInterstArguments.interest = _totalInterests.mul(
          (tempInterstArguments.capacityShare +
            tempInterstArguments.utilizationShare) / 2
        );
        lpPosition = _positionsCache[j].lpPosition;
        lpPosition.actualCollateralAmount += tempInterstArguments.interest;
        tempInterstArguments.remainingInterest -= tempInterstArguments.interest;
      }
    } else if (!tempInterstArguments.isTotUtilizationNotZero) {
      for (uint256 j = 0; j < lpNumbers; j++) {
        tempInterstArguments.capacityShare = capacityShares[j].div(
          tempInterstArguments.totalCapacity
        );
        tempInterstArguments.interest = _totalInterests.mul(
          tempInterstArguments.capacityShare
        );
        lpPosition = _positionsCache[j].lpPosition;
        lpPosition.actualCollateralAmount += tempInterstArguments.interest;
        tempInterstArguments.remainingInterest -= tempInterstArguments.interest;
      }
    } else {
      for (uint256 j = 0; j < lpNumbers; j++) {
        tempInterstArguments.utilizationShare = utilizationShares[j].div(
          tempInterstArguments.totalUtilization
        );
        tempInterstArguments.interest = _totalInterests.mul(
          tempInterstArguments.utilizationShare
        );
        lpPosition = _positionsCache[j].lpPosition;
        lpPosition.actualCollateralAmount += tempInterstArguments.interest;
        tempInterstArguments.remainingInterest -= tempInterstArguments.interest;
      }
    }

    lpPosition = _positionsCache[mostFundedIndex].lpPosition;
    lpPosition.actualCollateralAmount += tempInterstArguments.remainingInterest;
  }

  /**
   * @notice Calculate interest shares of each LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _capacityShares Array to be populated with the capacity shares of every LP
   * @param _utilizationShares Array to be populated with the utilization shares of every LP
   * @return totalCapacity Sum of all the LP's capacities
   * @return totalUtilization Sum of all the LP's utilizations
   * @return totalLPsCollateral Sum of all the LP's collaterals
   * @return mostFundedIndex Index in the positionsCache of the LP collateralizing more money
   */
  function _calculateInterestShares(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache,
    uint256[] memory _capacityShares,
    uint256[] memory _utilizationShares
  )
    internal
    view
    returns (
      uint256 totalCapacity,
      uint256 totalUtilization,
      uint256 totalLPsCollateral,
      uint256 mostFundedIndex
    )
  {
    TempInterstSharesArgs memory tempInterstSharesArgs;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      tempInterstSharesArgs.lp = _storageParams.activeLPs.at(j);
      ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition =
        _storageParams.lpPositions[tempInterstSharesArgs.lp];
      tempInterstSharesArgs.capacityShare = _calculateCapacity(
        lpPosition,
        _price,
        _collateralDecimals
      );
      tempInterstSharesArgs.utilizationShare = _calculateUtilization(
        lpPosition,
        _price,
        _collateralDecimals
      );
      _capacityShares[j] = tempInterstSharesArgs.capacityShare;
      totalCapacity += tempInterstSharesArgs.capacityShare;
      _utilizationShares[j] = tempInterstSharesArgs.utilizationShare;
      totalUtilization += tempInterstSharesArgs.utilizationShare;
      _positionsCache[j] = PositionCache(tempInterstSharesArgs.lp, lpPosition);
      totalLPsCollateral += lpPosition.actualCollateralAmount;
      tempInterstSharesArgs.bestShare = lpPosition.tokensCollateralized <=
        tempInterstSharesArgs.bestShare.share
        ? tempInterstSharesArgs.bestShare
        : BestShare(lpPosition.tokensCollateralized, j);
    }
    mostFundedIndex = tempInterstSharesArgs.bestShare.index;
  }

  /**
   * @notice Check if the input LP is registered
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lp Address of the LP
   * @return Return true if the LP is regitered, otherwise false
   */
  function _isRegisteredLP(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    address _lp
  ) internal view returns (bool) {
    return _storageParams.registeredLPs.contains(_lp);
  }

  /**
   * @notice Check if the input LP is active
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lp Address of the LP
   * @return Return true if the LP is active, otherwise false
   */
  function _isActiveLP(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    address _lp
  ) internal view returns (bool) {
    return _storageParams.activeLPs.contains(_lp);
  }

  /**
   * @notice Return the address of the LendingManager
   * @param _finder Synthereum finder
   * @return Address of the LendingManager
   */
  function _getLendingManager(ISynthereumFinder _finder)
    internal
    view
    returns (ILendingManager)
  {
    return
      ILendingManager(
        _finder.getImplementationAddress(SynthereumInterfaces.LendingManager)
      );
  }

  /**
   * @notice Return the address of the LendingStorageManager
   * @param _finder Synthereum finder
   * @return Address of the LendingStorageManager
   */
  function _getLendingStorageManager(ISynthereumFinder _finder)
    internal
    view
    returns (ILendingStorageManager)
  {
    return
      ILendingStorageManager(
        _finder.getImplementationAddress(
          SynthereumInterfaces.LendingStorageManager
        )
      );
  }

  /**
   * @notice Calculate and returns interest generated by the pool from the last update
   * @param _lendingManager Address of lendingManager
   * @return poolInterests Return interest generated by the pool
   * @return collateralDeposited Collateral deposited in the pool (LPs + users) (excluding last intrest amount calculation)
   */
  function _getLendingInterest(ILendingManager _lendingManager)
    internal
    view
    returns (uint256 poolInterests, uint256 collateralDeposited)
  {
    (poolInterests, , , collateralDeposited) = _lendingManager
      .getAccumulatedInterest(address(this));
  }

  /**
   * @notice Return the on-chain oracle price for a pair
   * @param _finder Synthereum finder
   * @param _priceIdentifier Price identifier
   * @return Latest rate of the pair
   */
  function _getPriceFeedRate(
    ISynthereumFinder _finder,
    bytes32 _priceIdentifier
  ) internal view returns (uint256) {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    return priceFeed.getLatestPrice(_priceIdentifier);
  }

  /**
   * @notice Given a collateral value to be exchanged, returns the fee amount, net collateral and synthetic tokens
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _totCollateralAmount Collateral amount to be exchanged
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Return netCollateralAmount, feeAmount and numTokens
   */
  function _calculateMint(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _totCollateralAmount,
    uint256 _price,
    uint8 _collateralDecimals
  )
    internal
    view
    returns (ISynthereumMultiLpLiquidityPoolEvents.MintValues memory)
  {
    uint256 feeAmount = _totCollateralAmount.mul(_storageParams.fee);

    uint256 netCollateralAmount = _totCollateralAmount - feeAmount;

    uint256 numTokens =
      _calculateNumberOfTokens(
        netCollateralAmount,
        _price,
        _collateralDecimals
      );

    return
      ISynthereumMultiLpLiquidityPoolEvents.MintValues(
        _totCollateralAmount,
        netCollateralAmount,
        feeAmount,
        numTokens
      );
  }

  /**
   * @notice Given a an amount of synthetic tokens to be exchanged, returns the fee amount, net collateral and gross collateral
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _numTokens Synthetic tokens amount to be exchanged
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Return netCollateralAmount, feeAmount and totCollateralAmount
   */
  function _calculateRedeem(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _numTokens,
    uint256 _price,
    uint8 _collateralDecimals
  )
    internal
    view
    returns (ISynthereumMultiLpLiquidityPoolEvents.RedeemValues memory)
  {
    uint256 totCollateralAmount =
      _calculateCollateralAmount(_numTokens, _price, _collateralDecimals);

    uint256 feeAmount = totCollateralAmount.mul(_storageParams.fee);

    uint256 netCollateralAmount = totCollateralAmount - feeAmount;

    return
      ISynthereumMultiLpLiquidityPoolEvents.RedeemValues(
        _numTokens,
        totCollateralAmount,
        feeAmount,
        netCollateralAmount
      );
  }

  /**
   * @notice Calculate and return the max capacity in synth tokens of the pool
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _finder Synthereum finder
   * @return maxCapacity Max capacity of the pool
   */
  function _calculateMaxCapacity(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _price,
    uint8 _collateralDecimals,
    ISynthereumFinder _finder
  ) internal view returns (uint256 maxCapacity) {
    (uint256 poolInterest, uint256 collateralDeposited) =
      SynthereumMultiLpLiquidityPoolLib._getLendingInterest(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder)
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        poolInterest,
        _price,
        _storageParams.totalSyntheticAsset,
        collateralDeposited,
        _collateralDecimals
      );

    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    uint256 lpCapacity;
    for (uint256 j = 0; j < positionsCache.length; j++) {
      lpPosition = positionsCache[j].lpPosition;
      lpCapacity = SynthereumMultiLpLiquidityPoolLib._calculateCapacity(
        lpPosition,
        _price,
        _collateralDecimals
      );
      maxCapacity += lpCapacity;
    }
  }

  /**
   * @notice Calculate profit or loss of each Lp
   * @param _price Actual price of the pair
   * @param _totalSynthTokens Amount of synthetic asset collateralized by the pool
   * @param _totalUserAmount Actual amount deposited by the users
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _mostFundedIndex Index in the positionsCache of the LP collateralizing more money
   */
  function _calculateProfitAndLoss(
    uint256 _price,
    uint256 _totalSynthTokens,
    uint256 _totalUserAmount,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache,
    uint256 _mostFundedIndex
  ) internal pure {
    if (_totalSynthTokens == 0) {
      return;
    }

    uint256 lpNumbers = _positionsCache.length;

    uint256 totalAssetValue =
      _calculateCollateralAmount(
        _totalSynthTokens,
        _price,
        _collateralDecimals
      );

    bool isLpGain = totalAssetValue < _totalUserAmount;

    uint256 totalProfitOrLoss =
      isLpGain
        ? _totalUserAmount - totalAssetValue
        : totalAssetValue - _totalUserAmount;

    uint256 remainingProfitOrLoss = totalProfitOrLoss;
    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    uint256 assetRatio;
    uint256 lpProfitOrLoss;
    for (uint256 j = 0; j < lpNumbers; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      assetRatio = lpPosition.tokensCollateralized.div(_totalSynthTokens);
      lpProfitOrLoss = totalProfitOrLoss.mul(assetRatio);
      lpPosition.actualCollateralAmount = isLpGain
        ? lpPosition.actualCollateralAmount + lpProfitOrLoss
        : lpPosition.actualCollateralAmount - lpProfitOrLoss;
      remainingProfitOrLoss -= lpProfitOrLoss;
    }

    lpPosition = _positionsCache[_mostFundedIndex].lpPosition;
    lpPosition.actualCollateralAmount = isLpGain
      ? lpPosition.actualCollateralAmount + remainingProfitOrLoss
      : lpPosition.actualCollateralAmount - remainingProfitOrLoss;
  }

  /**
   * @notice Calculate fee and synthetic asset of each Lp in a mint transaction
   * @param _mintValues ExchangeAmount, feeAmount and numTokens
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateMintTokensAndFee(
    ISynthereumMultiLpLiquidityPoolEvents.MintValues memory _mintValues,
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache
  ) internal pure {
    uint256 lpNumbers = _positionsCache.length;

    uint256[] memory capacityShares = new uint256[](lpNumbers);
    uint256 totalCapacity =
      _calculateMintShares(
        _price,
        _collateralDecimals,
        _positionsCache,
        capacityShares
      );

    require(
      totalCapacity >= _mintValues.numTokens,
      'No enough liquidity for covering mint operation'
    );

    TempSplitOperationArgs memory mintSplit;
    mintSplit.remainingTokens = _mintValues.numTokens;
    mintSplit.remainingFees = _mintValues.feeAmount;

    for (uint256 j = 0; j < lpNumbers; j++) {
      mintSplit.tokens = capacityShares[j].mul(
        _mintValues.numTokens.div(totalCapacity)
      );
      mintSplit.fees = _mintValues.feeAmount.mul(
        capacityShares[j].div(totalCapacity)
      );
      mintSplit.lpPosition = _positionsCache[j].lpPosition;
      mintSplit.bestShare = capacityShares[j] > mintSplit.bestShare.share
        ? BestShare(capacityShares[j], j)
        : mintSplit.bestShare;
      mintSplit.lpPosition.tokensCollateralized += mintSplit.tokens;
      mintSplit.lpPosition.actualCollateralAmount += mintSplit.fees;
      mintSplit.remainingTokens -= mintSplit.tokens;
      mintSplit.remainingFees = mintSplit.remainingFees - mintSplit.fees;
    }

    mintSplit.lpPosition = _positionsCache[mintSplit.bestShare.index]
      .lpPosition;
    mintSplit.lpPosition.tokensCollateralized += mintSplit.remainingTokens;
    mintSplit.lpPosition.actualCollateralAmount += mintSplit.remainingFees;
    (bool isOvercollateralized, ) =
      _isOvercollateralizedLP(
        mintSplit.lpPosition.actualCollateralAmount,
        mintSplit.lpPosition.overCollateralization,
        mintSplit.lpPosition.tokensCollateralized,
        _price,
        _collateralDecimals
      );
    require(
      isOvercollateralized,
      'No enough liquidity for covering split in mint operation'
    );
  }

  /**
   * @notice Calculate fee and synthetic asset of each Lp in a redeem transaction
   * @param _totalNumTokens Total amount of synethtic asset in the pool
   * @param _redeemNumTokens Total amount of synethtic asset to redeem
   * @param _feeAmount Total amount of fee to charge to the LPs
   * @param _withdrawDust Dust to add/decrease if transfer of bearing token from pool to lending manager is not exact
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateRedeemTokensAndFee(
    uint256 _totalNumTokens,
    uint256 _redeemNumTokens,
    uint256 _feeAmount,
    WithdrawDust memory _withdrawDust,
    PositionCache[] memory _positionsCache
  ) internal pure {
    uint256 lpNumbers = _positionsCache.length;
    TempSplitOperationArgs memory redeemSplit;
    redeemSplit.remainingTokens = _redeemNumTokens;
    redeemSplit.remainingFees = _feeAmount;

    for (uint256 j = 0; j < lpNumbers; j++) {
      redeemSplit.lpPosition = _positionsCache[j].lpPosition;
      redeemSplit.tokens = redeemSplit.lpPosition.tokensCollateralized.mul(
        _redeemNumTokens.div(_totalNumTokens)
      );
      redeemSplit.fees = _feeAmount.mul(
        redeemSplit.lpPosition.tokensCollateralized.div(_totalNumTokens)
      );
      redeemSplit.bestShare = redeemSplit.lpPosition.tokensCollateralized >
        redeemSplit.bestShare.share
        ? BestShare(redeemSplit.lpPosition.tokensCollateralized, j)
        : redeemSplit.bestShare;
      redeemSplit.lpPosition.tokensCollateralized -= redeemSplit.tokens;
      redeemSplit.lpPosition.actualCollateralAmount += redeemSplit.fees;
      redeemSplit.remainingTokens -= redeemSplit.tokens;
      redeemSplit.remainingFees -= redeemSplit.fees;
    }
    redeemSplit.lpPosition = _positionsCache[redeemSplit.bestShare.index]
      .lpPosition;
    redeemSplit.lpPosition.tokensCollateralized -= redeemSplit.remainingTokens;
    redeemSplit.lpPosition.actualCollateralAmount = _withdrawDust.isPositive
      ? redeemSplit.lpPosition.actualCollateralAmount +
        redeemSplit.remainingFees +
        _withdrawDust.amount
      : redeemSplit.lpPosition.actualCollateralAmount +
        redeemSplit.remainingFees -
        _withdrawDust.amount;
  }

  /**
   * @notice Calculate the new collateral amount of the LPs after the switching of lending module
   * @param _prevLpsCollateral Total amount of collateral holded by the LPs before this operation
   * @param _migrationValues Values returned by the lending manager after the migration
   * @param _overCollateralRequirement Percentage of overcollateralization to which a liquidation can triggered
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _mostFundedIndex Index of the LP with biggest amount of synt tokens held in his position
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateSwitchingOrMigratingCollateral(
    uint256 _prevLpsCollateral,
    ILendingManager.MigrateReturnValues memory _migrationValues,
    uint128 _overCollateralRequirement,
    uint256 _price,
    uint8 _collateralDecimals,
    uint256 _mostFundedIndex,
    PositionCache[] memory _positionsCache
  ) internal pure {
    TempMigrationArgs memory _tempMigrationArgs;
    _tempMigrationArgs.prevTotalAmount =
      _migrationValues.prevTotalCollateral +
      _migrationValues.poolInterest;
    _tempMigrationArgs.isLpGain =
      _migrationValues.actualTotalCollateral >
      _tempMigrationArgs.prevTotalAmount;
    _tempMigrationArgs.globalLpsProfitOrLoss = _tempMigrationArgs.isLpGain
      ? _migrationValues.actualTotalCollateral -
        _tempMigrationArgs.prevTotalAmount
      : _tempMigrationArgs.prevTotalAmount -
        _migrationValues.actualTotalCollateral;
    if (_tempMigrationArgs.globalLpsProfitOrLoss == 0) return;

    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    _tempMigrationArgs.actualLpsCollateral =
      _prevLpsCollateral +
      _migrationValues.poolInterest;
    _tempMigrationArgs.remainingAmount = _tempMigrationArgs
      .globalLpsProfitOrLoss;
    _tempMigrationArgs.lpNumbers = _positionsCache.length;
    for (uint256 j = 0; j < _tempMigrationArgs.lpNumbers; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      _tempMigrationArgs.share = lpPosition.actualCollateralAmount.div(
        _tempMigrationArgs.actualLpsCollateral
      );
      _tempMigrationArgs.shareAmount = _tempMigrationArgs
        .globalLpsProfitOrLoss
        .mul(_tempMigrationArgs.share);
      lpPosition.actualCollateralAmount = _tempMigrationArgs.isLpGain
        ? lpPosition.actualCollateralAmount + _tempMigrationArgs.shareAmount
        : lpPosition.actualCollateralAmount - _tempMigrationArgs.shareAmount;
      _tempMigrationArgs.remainingAmount -= _tempMigrationArgs.shareAmount;
      if (j != _mostFundedIndex) {
        (_tempMigrationArgs.isOvercollateralized, ) = _isOvercollateralizedLP(
          lpPosition.actualCollateralAmount,
          _overCollateralRequirement,
          lpPosition.tokensCollateralized,
          _price,
          _collateralDecimals
        );
        require(
          _tempMigrationArgs.isOvercollateralized,
          'LP below collateral requirement level'
        );
      }
    }

    lpPosition = _positionsCache[_mostFundedIndex].lpPosition;
    lpPosition.actualCollateralAmount = _tempMigrationArgs.isLpGain
      ? lpPosition.actualCollateralAmount + _tempMigrationArgs.remainingAmount
      : lpPosition.actualCollateralAmount - _tempMigrationArgs.remainingAmount;
    (_tempMigrationArgs.isOvercollateralized, ) = _isOvercollateralizedLP(
      lpPosition.actualCollateralAmount,
      _overCollateralRequirement,
      lpPosition.tokensCollateralized,
      _price,
      _collateralDecimals
    );
    require(
      _tempMigrationArgs.isOvercollateralized,
      'LP below collateral requirement level'
    );
  }

  /**
   * @notice Calculate capacity in tokens of each LP
   * @dev Utilization = (actualCollateralAmount / overCollateralization) * price - tokensCollateralized
   * @dev Return 0 if underCollateralized
   * @param _lpPosition Actual LP position
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Capacity of the LP
   */
  function _calculateCapacity(
    ISynthereumMultiLpLiquidityPool.LPPosition memory _lpPosition,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    uint256 maxCapacity =
      _calculateNumberOfTokens(
        _lpPosition.actualCollateralAmount.div(
          _lpPosition.overCollateralization
        ),
        _price,
        _collateralDecimals
      );
    return
      maxCapacity > _lpPosition.tokensCollateralized
        ? maxCapacity - _lpPosition.tokensCollateralized
        : 0;
  }

  /**
   * @notice Calculate utilization of an LP
   * @dev Utilization = (tokensCollateralized * price * overCollateralization) / actualCollateralAmount
   * @dev Capped to 1 in case of underCollateralization
   * @param _lpPosition Actual LP position
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Utilization of the LP
   */
  function _calculateUtilization(
    ISynthereumMultiLpLiquidityPool.LPPosition memory _lpPosition,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    return
      _lpPosition.actualCollateralAmount != 0
        ? PreciseUnitMath.min(
          _calculateCollateralAmount(
            _lpPosition
              .tokensCollateralized,
            _price,
            _collateralDecimals
          )
            .mul(_lpPosition.overCollateralization)
            .div(_lpPosition.actualCollateralAmount),
          PreciseUnitMath.PRECISE_UNIT
        )
        : _lpPosition.tokensCollateralized > 0
        ? PreciseUnitMath.PRECISE_UNIT
        : 0;
  }

  /**
   * @notice Calculate mint shares based on capacity
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _capacityShares Array to be populated with the capacity shares of every LPP
   * @return totalCapacity Sum of all the LP's capacities
   */
  function _calculateMintShares(
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache,
    uint256[] memory _capacityShares
  ) internal pure returns (uint256 totalCapacity) {
    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    uint256 capacityShare;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      capacityShare = _calculateCapacity(
        lpPosition,
        _price,
        _collateralDecimals
      );
      _capacityShares[j] = capacityShare;
      totalCapacity += capacityShare;
    }
  }

  /**
   * @notice Calculate synthetic token amount starting from an amount of collateral
   * @param _collateralAmount Amount of collateral from which you want to calculate synthetic token amount
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Amount of tokens after on-chain oracle conversion
   */
  function _calculateNumberOfTokens(
    uint256 _collateralAmount,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    return (_collateralAmount * (10**(18 - _collateralDecimals))).div(_price);
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token
   * @param _numTokens Amount of synthetic tokens used for the conversion
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Amount of collateral after on-chain oracle conversion
   */
  function _calculateCollateralAmount(
    uint256 _numTokens,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    return _numTokens.mul(_price) / (10**(18 - _collateralDecimals));
  }

  /**
   * @notice Return if an LP is overcollateralized and the max capacity of the LP
   * @param _actualCollateralAmount Actual collateral amount holded by the LP
   * @param _overCollateralization Overcollateralization requested
   * @param _tokens Tokens collateralized
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return isOvercollateralized True if LP is overcollateralized otherwise false
   * @return maxCapacity Max capcity in synth tokens of the LP
   */
  function _isOvercollateralizedLP(
    uint256 _actualCollateralAmount,
    uint256 _overCollateralization,
    uint256 _tokens,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (bool isOvercollateralized, uint256 maxCapacity) {
    maxCapacity = _calculateNumberOfTokens(
      _actualCollateralAmount.div(_overCollateralization),
      _price,
      _collateralDecimals
    );
    isOvercollateralized = maxCapacity >= _tokens;
  }
}