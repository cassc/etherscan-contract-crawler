// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  ILendingManager
} from '../../lending-module/interfaces/ILendingManager.sol';
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
import {ExplicitERC20} from '../../base/utils/ExplicitERC20.sol';
import {SynthereumMultiLpLiquidityPoolLib} from './MultiLpLiquidityPoolLib.sol';

/**
 * @title Multi LP Synthereum pool lib with main functions
 */

library SynthereumMultiLpLiquidityPoolMainLib {
  using PreciseUnitMath for uint256;
  using ExplicitERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  struct PositionLPInfoArgs {
    uint256 price;
    uint256 poolInterest;
    uint256 collateralDeposited;
    uint256 totalSynthTokens;
    uint256 overCollateralLimit;
    uint256[] capacityShares;
    uint256 totalCapacity;
    uint256 tokensValue;
    uint256 maxCapacity;
    uint8 decimals;
    uint256 utilization;
    uint256 totalUtilization;
  }

  // See IMultiLpLiquidityPoolEvents for events description
  event RegisteredLp(address indexed lp);

  event ActivatedLP(address indexed lp);

  event SetOvercollateralization(
    address indexed lp,
    uint256 overCollateralization
  );

  event DepositedLiquidity(
    address indexed lp,
    uint256 collateralSent,
    uint256 collateralDeposited
  );

  event WithdrawnLiquidity(
    address indexed lp,
    uint256 collateralWithdrawn,
    uint256 collateralReceived
  );

  event Minted(
    address indexed user,
    ISynthereumMultiLpLiquidityPoolEvents.MintValues mintvalues,
    address recipient
  );

  event Redeemed(
    address indexed user,
    ISynthereumMultiLpLiquidityPoolEvents.RedeemValues redeemvalues,
    address recipient
  );

  event Liquidated(
    address indexed user,
    address indexed lp,
    uint256 synthTokensInLiquidation,
    uint256 collateralAmount,
    uint256 bonusAmount,
    uint256 collateralReceived
  );

  /**
   * @notice Initialize pool
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _params Params used for initialization (see InitializationParams struct)
   */
  function initialize(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumMultiLpLiquidityPool.InitializationParams calldata _params
  ) external {
    require(
      _params.overCollateralRequirement > 0,
      'Overcollateral requirement must be bigger than 0%'
    );

    uint8 collTokenDecimals = _params.collateralToken.decimals();
    require(collTokenDecimals <= 18, 'Collateral has more than 18 decimals');

    require(
      _params.syntheticToken.decimals() == 18,
      'Synthetic token has more or less than 18 decimals'
    );

    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _params.finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );
    require(
      priceFeed.isPriceSupported(_params.priceIdentifier),
      'Price identifier not supported'
    );

    _storageParams.poolVersion = _params.version;
    _storageParams.collateralAsset = _params.collateralToken;
    _storageParams.collateralDecimals = collTokenDecimals;
    _storageParams.syntheticAsset = _params.syntheticToken;
    _storageParams.priceIdentifier = _params.priceIdentifier;
    _storageParams.overCollateralRequirement = _params
      .overCollateralRequirement;

    SynthereumMultiLpLiquidityPoolLib._setLiquidationReward(
      _storageParams,
      _params.liquidationReward
    );
    SynthereumMultiLpLiquidityPoolLib._setFee(_storageParams, _params.fee);
    SynthereumMultiLpLiquidityPoolLib._setLendingModule(
      _storageParams,
      _params.lendingModuleId
    );
  }

  /**
   * @notice Register a liquidity provider to the LP's whitelist
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lp Address of the LP
   */
  function registerLP(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    address _lp
  ) external {
    require(_storageParams.registeredLPs.add(_lp), 'LP already registered');
    emit RegisteredLp(_lp);
  }

  /**
   * @notice Add the Lp to the active list of the LPs and initialize collateral and overcollateralization
   * @notice Only a registered and inactive LP can call this function to add himself
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @param _overCollateralization Overcollateralization to set by the LP
   * @param _finder Synthereum finder
   * @param _msgSender Transaction sender
   * @return collateralDeposited Net collateral deposited in the LP position
   */
  function activateLP(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _collateralAmount,
    uint128 _overCollateralization,
    ISynthereumFinder _finder,
    address _msgSender
  ) external returns (uint256 collateralDeposited) {
    require(
      SynthereumMultiLpLiquidityPoolLib._isRegisteredLP(
        _storageParams,
        _msgSender
      ),
      'Sender must be a registered LP'
    );
    require(_collateralAmount > 0, 'No collateral deposited');
    require(
      _overCollateralization > _storageParams.overCollateralRequirement,
      'Overcollateralization must be bigger than overcollateral requirement'
    );

    ILendingManager.ReturnValues memory lendingValues =
      SynthereumMultiLpLiquidityPoolLib._lendingDeposit(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder),
        _msgSender,
        _storageParams.collateralAsset,
        _collateralAmount
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        _storageParams.collateralDecimals
      );

    SynthereumMultiLpLiquidityPoolLib._updateActualLPCollateral(
      _storageParams,
      positionsCache
    );

    collateralDeposited = lendingValues.tokensOut;
    _storageParams.lpPositions[_msgSender] = ISynthereumMultiLpLiquidityPool
      .LPPosition(collateralDeposited, 0, _overCollateralization);

    require(_storageParams.activeLPs.add(_msgSender), 'LP already active');

    emit ActivatedLP(_msgSender);
    emit DepositedLiquidity(_msgSender, _collateralAmount, collateralDeposited);
    emit SetOvercollateralization(_msgSender, _overCollateralization);
  }

  /**
   * @notice Add collateral to an active LP position
   * @notice Only an active LP can call this function to add collateral to his position
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @param _finder Synthereum finder
   * @param _msgSender Transaction sender
   * @return collateralDeposited Net collateral deposited in the LP position
   * @return newLpCollateralAmount Amount of collateral of the LP after the increase
   */
  function addLiquidity(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _collateralAmount,
    ISynthereumFinder _finder,
    address _msgSender
  )
    external
    returns (uint256 collateralDeposited, uint256 newLpCollateralAmount)
  {
    require(
      SynthereumMultiLpLiquidityPoolLib._isActiveLP(_storageParams, _msgSender),
      'Sender must be an active LP'
    );
    require(_collateralAmount > 0, 'No collateral added');

    ILendingManager.ReturnValues memory lendingValues =
      SynthereumMultiLpLiquidityPoolLib._lendingDeposit(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder),
        _msgSender,
        _storageParams.collateralAsset,
        _collateralAmount
      );

    SynthereumMultiLpLiquidityPoolLib.TempStorageArgs memory tempStorage =
      SynthereumMultiLpLiquidityPoolLib.TempStorageArgs(
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralDecimals
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        tempStorage.decimals
      );

    collateralDeposited = lendingValues.tokensOut;
    newLpCollateralAmount = SynthereumMultiLpLiquidityPoolLib
      ._updateAndIncreaseActualLPCollateral(
      _storageParams,
      positionsCache,
      _msgSender,
      collateralDeposited
    );

    emit DepositedLiquidity(_msgSender, _collateralAmount, collateralDeposited);
  }

  /**
   * @notice Withdraw collateral from an active LP position
   * @notice Only an active LP can call this function to withdraw collateral from his position
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _collateralAmount Collateral amount to withdraw by the LP
   * @param _finder Synthereum finder
   * @param _msgSender Transaction sender
   * @return collateralRemoved Net collateral decreased form the position
   * @return collateralReceived Collateral received from the withdrawal
   * @return newLpCollateralAmount Amount of collateral of the LP after the decrease
   */
  function removeLiquidity(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _collateralAmount,
    ISynthereumFinder _finder,
    address _msgSender
  )
    external
    returns (
      uint256 collateralRemoved,
      uint256 collateralReceived,
      uint256 newLpCollateralAmount
    )
  {
    require(
      SynthereumMultiLpLiquidityPoolLib._isActiveLP(_storageParams, _msgSender),
      'Sender must be an active LP'
    );
    require(_collateralAmount > 0, 'No collateral withdrawn');

    (ILendingManager.ReturnValues memory lendingValues, ) =
      SynthereumMultiLpLiquidityPoolLib._lendingWithdraw(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder),
        _msgSender,
        _collateralAmount
      );

    SynthereumMultiLpLiquidityPoolLib.TempStorageArgs memory tempStorage =
      SynthereumMultiLpLiquidityPoolLib.TempStorageArgs(
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralDecimals
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        tempStorage.decimals
      );

    collateralRemoved = lendingValues.tokensOut;
    collateralReceived = lendingValues.tokensTransferred;
    newLpCollateralAmount = SynthereumMultiLpLiquidityPoolLib
      ._updateAndDecreaseActualLPCollateral(
      _storageParams,
      positionsCache,
      _msgSender,
      collateralRemoved,
      tempStorage.price,
      tempStorage.decimals
    );

    emit WithdrawnLiquidity(_msgSender, collateralRemoved, collateralReceived);
  }

  /**
   * @notice Set the overCollateralization by an active LP
   * @notice This can be called only by an active LP
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _overCollateralization New overCollateralization
   * @param _finder Synthereum finder
   * @param _msgSender Transaction sender
   */
  function setOvercollateralization(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint128 _overCollateralization,
    ISynthereumFinder _finder,
    address _msgSender
  ) external {
    require(
      SynthereumMultiLpLiquidityPoolLib._isActiveLP(_storageParams, _msgSender),
      'Sender must be an active LP'
    );

    require(
      _overCollateralization > _storageParams.overCollateralRequirement,
      'Overcollateralization must be bigger than overcollateral requirement'
    );

    ILendingManager.ReturnValues memory lendingValues =
      SynthereumMultiLpLiquidityPoolLib
        ._getLendingManager(_finder)
        .updateAccumulatedInterest();

    SynthereumMultiLpLiquidityPoolLib.TempStorageArgs memory tempStorage =
      SynthereumMultiLpLiquidityPoolLib.TempStorageArgs(
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralDecimals
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        tempStorage.decimals
      );

    SynthereumMultiLpLiquidityPoolLib._updateAndModifyActualLPOverCollateral(
      _storageParams,
      positionsCache,
      _msgSender,
      _overCollateralization,
      tempStorage.price,
      tempStorage.decimals
    );

    emit SetOvercollateralization(_msgSender, _overCollateralization);
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _mintParams Input parameters for minting (see MintParams struct)
   * @param _finder Synthereum finder
   * @param _msgSender Transaction sender
   * @return Amount of synthetic tokens minted by a user
   * @return Amount of collateral paid by the user as fee
   */
  function mint(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumMultiLpLiquidityPool.MintParams calldata _mintParams,
    ISynthereumFinder _finder,
    address _msgSender
  ) external returns (uint256, uint256) {
    require(_mintParams.collateralAmount > 0, 'No collateral sent');

    ILendingManager.ReturnValues memory lendingValues =
      SynthereumMultiLpLiquidityPoolLib._lendingDeposit(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder),
        _msgSender,
        _storageParams.collateralAsset,
        _mintParams.collateralAmount
      );

    SynthereumMultiLpLiquidityPoolLib.TempStorageArgs memory tempStorage =
      SynthereumMultiLpLiquidityPoolLib.TempStorageArgs(
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralDecimals
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        tempStorage.decimals
      );

    ISynthereumMultiLpLiquidityPoolEvents.MintValues memory mintValues =
      SynthereumMultiLpLiquidityPoolLib._calculateMint(
        _storageParams,
        lendingValues.tokensOut,
        tempStorage.price,
        tempStorage.decimals
      );

    require(
      mintValues.numTokens >= _mintParams.minNumTokens,
      'Number of tokens less than minimum limit'
    );

    SynthereumMultiLpLiquidityPoolLib._calculateMintTokensAndFee(
      mintValues,
      tempStorage.price,
      tempStorage.decimals,
      positionsCache
    );

    SynthereumMultiLpLiquidityPoolLib._updateActualLPPositions(
      _storageParams,
      positionsCache
    );

    _storageParams.totalSyntheticAsset =
      tempStorage.totalSyntheticAsset +
      mintValues.numTokens;

    _storageParams.syntheticAsset.mint(
      _mintParams.recipient,
      mintValues.numTokens
    );

    mintValues.totalCollateral = _mintParams.collateralAmount;

    emit Minted(_msgSender, mintValues, _mintParams.recipient);

    return (mintValues.numTokens, mintValues.feeAmount);
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @param _finder Synthereum finder
   * @param _msgSender Transaction sender
   * @return Amount of collateral redeemed by user
   * @return Amount of collateral paid by user as fee
   */
  function redeem(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumMultiLpLiquidityPool.RedeemParams calldata _redeemParams,
    ISynthereumFinder _finder,
    address _msgSender
  ) external returns (uint256, uint256) {
    require(_redeemParams.numTokens > 0, 'No tokens sent');

    SynthereumMultiLpLiquidityPoolLib.TempStorageArgs memory tempStorage =
      SynthereumMultiLpLiquidityPoolLib.TempStorageArgs(
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        _storageParams.collateralDecimals
      );

    ISynthereumMultiLpLiquidityPoolEvents.RedeemValues memory redeemValues =
      SynthereumMultiLpLiquidityPoolLib._calculateRedeem(
        _storageParams,
        _redeemParams.numTokens,
        tempStorage.price,
        tempStorage.decimals
      );

    (
      ILendingManager.ReturnValues memory lendingValues,
      SynthereumMultiLpLiquidityPoolLib.WithdrawDust memory withdrawDust
    ) =
      SynthereumMultiLpLiquidityPoolLib._lendingWithdraw(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder),
        _redeemParams.recipient,
        redeemValues.collateralAmount
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        tempStorage.decimals
      );

    require(
      lendingValues.tokensTransferred >= _redeemParams.minCollateral,
      'Collateral amount less than minimum limit'
    );

    SynthereumMultiLpLiquidityPoolLib._calculateRedeemTokensAndFee(
      tempStorage.totalSyntheticAsset,
      _redeemParams.numTokens,
      redeemValues.feeAmount,
      withdrawDust,
      positionsCache
    );

    SynthereumMultiLpLiquidityPoolLib._updateActualLPPositions(
      _storageParams,
      positionsCache
    );

    _storageParams.totalSyntheticAsset =
      tempStorage.totalSyntheticAsset -
      _redeemParams.numTokens;

    SynthereumMultiLpLiquidityPoolLib._burnSyntheticTokens(
      _storageParams.syntheticAsset,
      _redeemParams.numTokens,
      _msgSender
    );

    redeemValues.collateralAmount = lendingValues.tokensTransferred;

    emit Redeemed(_msgSender, redeemValues, _redeemParams.recipient);

    return (redeemValues.collateralAmount, redeemValues.feeAmount);
  }

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lp LP that the the user wants to liquidate
   * @param _numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @param _finder Synthereum finder
   * @param _liquidator Liquidator of the LP position
   * @return Amount of collateral received (Amount of collateral + bonus)
   */
  function liquidate(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    address _lp,
    uint256 _numSynthTokens,
    ISynthereumFinder _finder,
    address _liquidator
  ) external returns (uint256) {

      SynthereumMultiLpLiquidityPoolLib.LiquidationUpdateArgs
        memory liquidationUpdateArgs
    ;
    liquidationUpdateArgs.liquidator = _liquidator;

    require(
      SynthereumMultiLpLiquidityPoolLib._isActiveLP(_storageParams, _lp),
      'LP is not active'
    );

    liquidationUpdateArgs.tempStorageArgs = SynthereumMultiLpLiquidityPoolLib
      .TempStorageArgs(
      SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
        _finder,
        _storageParams.priceIdentifier
      ),
      _storageParams.totalSyntheticAsset,
      _storageParams.collateralDecimals
    );

    liquidationUpdateArgs.lendingManager = SynthereumMultiLpLiquidityPoolLib
      ._getLendingManager(_finder);
    liquidationUpdateArgs.overCollateralRequirement = _storageParams
      .overCollateralRequirement;

    (uint256 poolInterest, uint256 collateralDeposited) =
      SynthereumMultiLpLiquidityPoolLib._getLendingInterest(
        liquidationUpdateArgs.lendingManager
      );

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        poolInterest,
        liquidationUpdateArgs.tempStorageArgs.price,
        liquidationUpdateArgs.tempStorageArgs.totalSyntheticAsset,
        collateralDeposited,
        liquidationUpdateArgs.tempStorageArgs.decimals
      );

    (
      uint256 tokensInLiquidation,
      uint256 collateralAmount,
      uint256 bonusAmount,
      uint256 collateralReceived
    ) =
      SynthereumMultiLpLiquidityPoolLib._updateAndLiquidate(
        _storageParams,
        positionsCache,
        _lp,
        _numSynthTokens,
        liquidationUpdateArgs
      );

    _storageParams.totalSyntheticAsset =
      liquidationUpdateArgs.tempStorageArgs.totalSyntheticAsset -
      tokensInLiquidation;

    SynthereumMultiLpLiquidityPoolLib._burnSyntheticTokens(
      _storageParams.syntheticAsset,
      tokensInLiquidation,
      _liquidator
    );

    emit Liquidated(
      _liquidator,
      _lp,
      tokensInLiquidation,
      collateralAmount,
      bonusAmount,
      collateralReceived
    );

    return collateralReceived;
  }

  /**
   * @notice Update interests and positions ov every LP
   * @notice Everyone can call this function
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _finder Synthereum finder
   */
  function updatePositions(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumFinder _finder
  ) external {
    ILendingManager.ReturnValues memory lendingValues =
      SynthereumMultiLpLiquidityPoolLib
        ._getLendingManager(_finder)
        .updateAccumulatedInterest();

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        lendingValues.poolInterest,
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        lendingValues.prevTotalCollateral,
        _storageParams.collateralDecimals
      );

    SynthereumMultiLpLiquidityPoolLib._updateActualLPPositions(
      _storageParams,
      positionsCache
    );
  }

  /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _bearingAmount Amount of bearing token to transfer
   * @param _finder Synthereum finder
   * @return bearingAmountOut Real bearing amount transferred to the lending manager
   */
  function transferToLendingManager(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _bearingAmount,
    ISynthereumFinder _finder
  ) external returns (uint256 bearingAmountOut) {
    ILendingManager lendingManager =
      SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder);
    require(
      msg.sender == address(lendingManager),
      'Sender must be the lending manager'
    );

    (uint256 poolInterest, uint256 totalActualCollateral) =
      SynthereumMultiLpLiquidityPoolLib._getLendingInterest(lendingManager);

    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        poolInterest,
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.totalSyntheticAsset,
        totalActualCollateral,
        _storageParams.collateralDecimals
      );

    SynthereumMultiLpLiquidityPoolLib._updateActualLPPositions(
      _storageParams,
      positionsCache
    );

    (uint256 poolBearingValue, address bearingToken) =
      lendingManager.collateralToInterestToken(
        address(this),
        totalActualCollateral + poolInterest
      );

    (uint256 amountOut, uint256 remainingBearingValue) =
      IERC20(bearingToken).explicitSafeTransfer(msg.sender, _bearingAmount);

    require(remainingBearingValue >= poolBearingValue, 'Unfunded pool');

    bearingAmountOut = amountOut;
  }

  /**
   * @notice Set new liquidation reward percentage
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _newLiquidationReward New liquidation reward percentage
   */
  function setLiquidationReward(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint64 _newLiquidationReward
  ) external {
    SynthereumMultiLpLiquidityPoolLib._setLiquidationReward(
      _storageParams,
      _newLiquidationReward
    );
  }

  /**
   * @notice Set new fee percentage
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _newFee New fee percentage
   */
  function setFee(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint64 _newFee
  ) external {
    SynthereumMultiLpLiquidityPoolLib._setFee(_storageParams, _newFee);
  }

  /**
   * @notice Get all the registered LPs of this pool
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @return The list of addresses of all the registered LPs in the pool.
   */
  function getRegisteredLPs(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams
  ) external view returns (address[] memory) {
    uint256 numberOfLPs = _storageParams.registeredLPs.length();
    address[] memory lpList = new address[](numberOfLPs);
    for (uint256 j = 0; j < numberOfLPs; j++) {
      lpList[j] = _storageParams.registeredLPs.at(j);
    }
    return lpList;
  }

  /**
   * @notice Get all the active LPs of this pool
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @return The list of addresses of all the active LPs in the pool.
   */
  function getActiveLPs(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams
  ) external view returns (address[] memory) {
    uint256 numberOfLPs = _storageParams.activeLPs.length();
    address[] memory lpList = new address[](numberOfLPs);
    for (uint256 j = 0; j < numberOfLPs; j++) {
      lpList[j] = _storageParams.activeLPs.at(j);
    }
    return lpList;
  }

  /**
   * @notice Returns the total amounts of collateral
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _finder Synthereum finder
   * @return usersCollateral Total collateral amount currently holded by users
   * @return lpsCollateral Total collateral amount currently holded by LPs
   * @return totalCollateral Total collateral amount currently holded by users + LPs
   */
  function totalCollateralAmount(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumFinder _finder
  )
    external
    view
    returns (
      uint256 usersCollateral,
      uint256 lpsCollateral,
      uint256 totalCollateral
    )
  {
    usersCollateral = SynthereumMultiLpLiquidityPoolLib
      ._calculateCollateralAmount(
      _storageParams.totalSyntheticAsset,
      SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
        _finder,
        _storageParams.priceIdentifier
      ),
      _storageParams.collateralDecimals
    );

    (uint256 poolInterest, uint256 totalActualCollateral) =
      SynthereumMultiLpLiquidityPoolLib._getLendingInterest(
        SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder)
      );

    totalCollateral = totalActualCollateral + poolInterest;

    lpsCollateral = totalCollateral - usersCollateral;
  }

  /**
   * @notice Returns the max capacity in synth assets of all the LPs
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _finder Synthereum finder
   * @return maxCapacity Total max capacity of the pool
   */
  function maxTokensCapacity(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumFinder _finder
  ) external view returns (uint256 maxCapacity) {
    uint256 price =
      SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
        _finder,
        _storageParams.priceIdentifier
      );

    uint8 decimals = _storageParams.collateralDecimals;

    maxCapacity = SynthereumMultiLpLiquidityPoolLib._calculateMaxCapacity(
      _storageParams,
      price,
      decimals,
      _finder
    );
  }

  /**
   * @notice Returns the lending protocol info
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _finder Synthereum finder
   * @return lendingId Name of the lending module
   * @return bearingToken Address of the bearing token held by the pool for interest accrual
   */
  function lendingProtocolInfo(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    ISynthereumFinder _finder
  ) external view returns (string memory lendingId, address bearingToken) {
    lendingId = _storageParams.lendingModuleId;
    bearingToken = SynthereumMultiLpLiquidityPoolLib
      ._getLendingStorageManager(_finder)
      .getInterestBearingToken(address(this));
  }

  /**
   * @notice Returns the LP parametrs info
   * @notice Mint, redeem and intreest shares are round down (division dust not included)
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _lp Address of the LP
   * @param _finder Synthereum finder
   * @return info Info of the input LP (see LPInfo struct)
   */
  function positionLPInfo(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    address _lp,
    ISynthereumFinder _finder
  ) external view returns (ISynthereumMultiLpLiquidityPool.LPInfo memory info) {
    require(
      SynthereumMultiLpLiquidityPoolLib._isActiveLP(_storageParams, _lp),
      'LP not active'
    );

    PositionLPInfoArgs memory positionLPInfoArgs;
    positionLPInfoArgs.price = SynthereumMultiLpLiquidityPoolLib
      ._getPriceFeedRate(_finder, _storageParams.priceIdentifier);

    (
      positionLPInfoArgs.poolInterest,
      positionLPInfoArgs.collateralDeposited
    ) = SynthereumMultiLpLiquidityPoolLib._getLendingInterest(
      SynthereumMultiLpLiquidityPoolLib._getLendingManager(_finder)
    );

    positionLPInfoArgs.totalSynthTokens = _storageParams.totalSyntheticAsset;

    positionLPInfoArgs.decimals = _storageParams.collateralDecimals;
    (
      SynthereumMultiLpLiquidityPoolLib.PositionCache[] memory positionsCache,
      ,

    ) =
      SynthereumMultiLpLiquidityPoolLib._calculateNewPositions(
        _storageParams,
        positionLPInfoArgs.poolInterest,
        positionLPInfoArgs.price,
        positionLPInfoArgs.totalSynthTokens,
        positionLPInfoArgs.collateralDeposited,
        positionLPInfoArgs.decimals
      );

    positionLPInfoArgs.overCollateralLimit = _storageParams
      .overCollateralRequirement;

    positionLPInfoArgs.capacityShares = new uint256[](positionsCache.length);
    positionLPInfoArgs.totalCapacity = SynthereumMultiLpLiquidityPoolLib
      ._calculateMintShares(
      positionLPInfoArgs.price,
      positionLPInfoArgs.decimals,
      positionsCache,
      positionLPInfoArgs.capacityShares
    );

    ISynthereumMultiLpLiquidityPool.LPPosition memory lpPosition;
    for (uint256 j = 0; j < positionsCache.length; j++) {
      lpPosition = positionsCache[j].lpPosition;
      positionLPInfoArgs.tokensValue = SynthereumMultiLpLiquidityPoolLib
        ._calculateCollateralAmount(
        lpPosition.tokensCollateralized,
        positionLPInfoArgs.price,
        positionLPInfoArgs.decimals
      );
      if (positionsCache[j].lp == _lp) {
        info.actualCollateralAmount = lpPosition.actualCollateralAmount;
        info.tokensCollateralized = lpPosition.tokensCollateralized;
        info.overCollateralization = lpPosition.overCollateralization;
        info.capacity = positionLPInfoArgs.capacityShares[j];
        info.utilization = lpPosition.actualCollateralAmount != 0
          ? PreciseUnitMath.min(
            (
              positionLPInfoArgs.tokensValue.mul(
                lpPosition.overCollateralization
              )
            )
              .div(lpPosition.actualCollateralAmount),
            PreciseUnitMath.PRECISE_UNIT
          )
          : lpPosition.tokensCollateralized > 0
          ? PreciseUnitMath.PRECISE_UNIT
          : 0;
        positionLPInfoArgs.totalUtilization += info.utilization;
        (
          info.isOvercollateralized,
          positionLPInfoArgs.maxCapacity
        ) = SynthereumMultiLpLiquidityPoolLib._isOvercollateralizedLP(
          lpPosition.actualCollateralAmount,
          positionLPInfoArgs.overCollateralLimit,
          lpPosition.tokensCollateralized,
          positionLPInfoArgs.price,
          positionLPInfoArgs.decimals
        );
        info.coverage = lpPosition.tokensCollateralized != 0
          ? PreciseUnitMath.PRECISE_UNIT +
            (
              positionLPInfoArgs.overCollateralLimit.mul(
                positionLPInfoArgs.maxCapacity.div(
                  lpPosition.tokensCollateralized
                )
              )
            )
          : lpPosition.actualCollateralAmount == 0
          ? 0
          : PreciseUnitMath.maxUint256();
        info.mintShares = positionLPInfoArgs.totalCapacity != 0
          ? positionLPInfoArgs.capacityShares[j].div(
            positionLPInfoArgs.totalCapacity
          )
          : 0;
        info.redeemShares = positionLPInfoArgs.totalSynthTokens != 0
          ? lpPosition.tokensCollateralized.div(
            positionLPInfoArgs.totalSynthTokens
          )
          : 0;
      } else {
        positionLPInfoArgs.utilization = lpPosition.actualCollateralAmount != 0
          ? PreciseUnitMath.min(
            (
              positionLPInfoArgs.tokensValue.mul(
                lpPosition.overCollateralization
              )
            )
              .div(lpPosition.actualCollateralAmount),
            PreciseUnitMath.PRECISE_UNIT
          )
          : lpPosition.tokensCollateralized > 0
          ? PreciseUnitMath.PRECISE_UNIT
          : 0;
        positionLPInfoArgs.totalUtilization += positionLPInfoArgs.utilization;
      }
    }
    info.interestShares = (positionLPInfoArgs.totalCapacity > 0 &&
      positionLPInfoArgs.totalUtilization > 0)
      ? ((info.mintShares +
        (info.utilization.div(positionLPInfoArgs.totalUtilization))) / 2)
      : positionLPInfoArgs.totalUtilization == 0
      ? info.mintShares
      : info.utilization.div(positionLPInfoArgs.totalUtilization);
    return info;
  }

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust, reverting due to dust splitting and undercaps
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param _collateralAmount Input collateral amount to be exchanged
   * @param _finder Synthereum finder
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _collateralAmount,
    ISynthereumFinder _finder
  ) external view returns (uint256 synthTokensReceived, uint256 feePaid) {
    require(_collateralAmount > 0, 'No input collateral');

    uint256 price =
      SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
        _finder,
        _storageParams.priceIdentifier
      );
    uint8 decimals = _storageParams.collateralDecimals;

    ISynthereumMultiLpLiquidityPoolEvents.MintValues memory mintValues =
      SynthereumMultiLpLiquidityPoolLib._calculateMint(
        _storageParams,
        _collateralAmount,
        price,
        decimals
      );

    uint256 maxCapacity =
      SynthereumMultiLpLiquidityPoolLib._calculateMaxCapacity(
        _storageParams,
        price,
        decimals,
        _finder
      );

    require(maxCapacity >= mintValues.numTokens, 'No enough liquidity');

    return (mintValues.numTokens, mintValues.feeAmount);
  }

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check edge case conditions like lending manager dust and undercaps
   * @param _storageParams Struct containing all storage variables of a pool (See Storage struct)
   * @param  _syntTokensAmount Amount of synthetic tokens to be exchanged
   * @param _finder Synthereum finder
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(
    ISynthereumMultiLpLiquidityPool.Storage storage _storageParams,
    uint256 _syntTokensAmount,
    ISynthereumFinder _finder
  ) external view returns (uint256 collateralAmountReceived, uint256 feePaid) {
    require(_syntTokensAmount > 0, 'No tokens sent');

    ISynthereumMultiLpLiquidityPoolEvents.RedeemValues memory redeemValues =
      SynthereumMultiLpLiquidityPoolLib._calculateRedeem(
        _storageParams,
        _syntTokensAmount,
        SynthereumMultiLpLiquidityPoolLib._getPriceFeedRate(
          _finder,
          _storageParams.priceIdentifier
        ),
        _storageParams.collateralDecimals
      );

    require(
      _syntTokensAmount <= _storageParams.totalSyntheticAsset,
      'No enough synth tokens'
    );

    return (redeemValues.collateralAmount, redeemValues.feeAmount);
  }
}