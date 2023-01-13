// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumLiquidityPool} from './interfaces/ILiquidityPool.sol';
import {
  ISynthereumLiquidityPoolStorage
} from './interfaces/ILiquidityPoolStorage.sol';
import {
  ISynthereumLiquidityPoolGeneral
} from './interfaces/ILiquidityPoolGeneral.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {SynthereumLiquidityPoolLib} from './LiquidityPoolLib.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {ERC2771Context} from '../../common/ERC2771Context.sol';
import {
  AccessControlEnumerable,
  Context
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Synthetic token Issuer Contract
 * @notice Collects collateral and issues synthetic assets
 */
contract SynthereumLiquidityPool is
  ISynthereumLiquidityPoolStorage,
  ISynthereumLiquidityPool,
  ReentrancyGuard,
  ERC2771Context,
  AccessControlEnumerable
{
  using SynthereumLiquidityPoolLib for Storage;
  using SynthereumLiquidityPoolLib for Liquidation;

  struct ConstructorParams {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum pool version
    uint8 version;
    // ERC20 collateral token
    IStandardERC20 collateralToken;
    // ERC20 synthetic token
    IMintableBurnableERC20 syntheticToken;
    // The addresses of admin, maintainer, liquidity provider
    Roles roles;
    // Overcollateralization percentage
    uint256 overCollateralization;
    // The feeData structure
    FeeData feeData;
    // Identifier of price to be used in the price feed
    bytes32 priceIdentifier;
    // Percentage of overcollateralization to which a liquidation can triggered
    uint256 collateralRequirement;
    // Percentage of reward for correct liquidation by a liquidator
    uint256 liquidationReward;
  }

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'POOL';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  //----------------------------------------
  // Storage
  //----------------------------------------

  Storage private poolStorage;

  LPPosition private lpPosition;

  Liquidation private liquidationData;

  FeeStatus private feeStatus;

  Shutdown private emergencyShutdownData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Mint(
    address indexed account,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Redeem(
    address indexed account,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid,
    address recipient
  );

  event Exchange(
    address indexed account,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event WithdrawLiquidity(
    address indexed lp,
    uint256 liquidityWithdrawn,
    uint256 remainingLiquidity
  );

  event IncreaseCollateral(
    address indexed lp,
    uint256 collateralAdded,
    uint256 newTotalCollateral
  );

  event DecreaseCollateral(
    address indexed lp,
    uint256 collateralRemoved,
    uint256 newTotalCollateral
  );

  event ClaimFee(
    address indexed claimer,
    uint256 feeAmount,
    uint256 totalRemainingFees
  );

  event Liquidate(
    address indexed liquidator,
    uint256 tokensLiquidated,
    uint256 price,
    uint256 collateralExpected,
    uint256 collateralReceived,
    uint256 rewardReceived
  );

  event EmergencyShutdown(
    uint256 timestamp,
    uint256 price,
    uint256 finalCollateral
  );

  event Settle(
    address indexed account,
    uint256 numTokensSettled,
    uint256 collateralExpected,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);

  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event SetOverCollateralization(uint256 overCollateralization);

  event SetLiquidationReward(uint256 liquidationReward);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, _msgSender()),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, _msgSender()),
      'Sender must be the liquidity provider'
    );
    _;
  }

  modifier notEmergencyShutdown() {
    require(emergencyShutdownData.timestamp == 0, 'Pool emergency shutdown');
    _;
  }

  modifier isEmergencyShutdown() {
    require(
      emergencyShutdownData.timestamp != 0,
      'Pool not emergency shutdown'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructor of liquidity pool

   */
  constructor(ConstructorParams memory params) nonReentrant {
    poolStorage.initialize(
      liquidationData,
      params.finder,
      params.version,
      params.collateralToken,
      params.syntheticToken,
      FixedPoint.Unsigned(params.overCollateralization),
      params.priceIdentifier,
      FixedPoint.Unsigned(params.collateralRequirement),
      FixedPoint.Unsigned(params.liquidationReward)
    );
    poolStorage.setFeePercentage(params.feeData.feePercentage);
    poolStorage.setFeeRecipients(
      params.feeData.feeRecipients,
      params.feeData.feeProportions
    );
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, params.roles.admin);
    _setupRole(MAINTAINER_ROLE, params.roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, params.roles.liquidityProvider);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata mintParams)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 syntheticTokensMinted, uint256 feePaid)
  {
    (syntheticTokensMinted, feePaid) = poolStorage.mint(
      lpPosition,
      feeStatus,
      mintParams,
      _msgSender()
    );
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata redeemParams)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 collateralRedeemed, uint256 feePaid)
  {
    (collateralRedeemed, feePaid) = poolStorage.redeem(
      lpPosition,
      feeStatus,
      redeemParams,
      _msgSender()
    );
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams calldata exchangeParams)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 destNumTokensMinted, uint256 feePaid)
  {
    (destNumTokensMinted, feePaid) = poolStorage.exchange(
      lpPosition,
      feeStatus,
      exchangeParams,
      _msgSender()
    );
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registered in the PoolRegister contract
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   * @param recipient Recipient to which send synthetic token minted
   */
  function exchangeMint(
    uint256 collateralAmount,
    uint256 numTokens,
    address recipient
  ) external override notEmergencyShutdown nonReentrant {
    poolStorage.exchangeMint(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens),
      recipient
    );
  }

  /**
   * @notice Withdraw unused deposited collateral by the LP
   * @notice Only a sender with LP role can call this function
   * @param collateralAmount Collateral to be withdrawn
   * @return remainingLiquidity Remaining unused collateral in the pool
   */
  function withdrawLiquidity(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    notEmergencyShutdown
    nonReentrant
    returns (uint256 remainingLiquidity)
  {
    remainingLiquidity = poolStorage.withdrawLiquidity(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(collateralAmount),
      _msgSender()
    );
  }

  /**
   * @notice Increase collaterallization of Lp position
   * @notice Only a sender with LP role can call this function
   * @param collateralToTransfer Collateral to be transferred before increase collateral in the position
   * @param collateralToIncrease Collateral to be added to the position
   * @return newTotalCollateral New total collateral amount
   */
  function increaseCollateral(
    uint256 collateralToTransfer,
    uint256 collateralToIncrease
  )
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 newTotalCollateral)
  {
    newTotalCollateral = poolStorage.increaseCollateral(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(collateralToTransfer),
      FixedPoint.Unsigned(collateralToIncrease),
      _msgSender()
    );
  }

  /**
   * @notice Decrease collaterallization of Lp position
   * @notice Check that final poosition is not undercollateralized
   * @notice Only a sender with LP role can call this function
   * @param collateralToDecrease Collateral to decreased from the position
   * @param collateralToWithdraw Collateral to be transferred to the LP
   * @return newTotalCollateral New total collateral amount
   */
  function decreaseCollateral(
    uint256 collateralToDecrease,
    uint256 collateralToWithdraw
  )
    external
    override
    onlyLiquidityProvider
    notEmergencyShutdown
    nonReentrant
    returns (uint256 newTotalCollateral)
  {
    newTotalCollateral = poolStorage.decreaseCollateral(
      lpPosition,
      liquidationData,
      feeStatus,
      FixedPoint.Unsigned(collateralToDecrease),
      FixedPoint.Unsigned(collateralToWithdraw),
      _msgSender()
    );
  }

  /**
   * @notice Withdraw fees gained by the sender
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee()
    external
    override
    nonReentrant
    returns (uint256 feeClaimed)
  {
    feeClaimed = poolStorage.claimFee(feeStatus, _msgSender());
  }

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return synthTokensLiquidated Amount of synthetic tokens liquidated
   * @return collateralReceived Amount of received collateral equal to the value of tokens liquidated
   * @return rewardAmount Amount of received collateral as reward for the liquidation
   */
  function liquidate(uint256 numSynthTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (
      uint256 synthTokensLiquidated,
      uint256 collateralReceived,
      uint256 rewardAmount
    )
  {
    (synthTokensLiquidated, collateralReceived, rewardAmount) = poolStorage
      .liquidate(
      lpPosition,
      liquidationData,
      feeStatus,
      FixedPoint.Unsigned(numSynthTokens),
      _msgSender()
    );
  }

  /**
   * @notice Shutdown the pool in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 timestamp, uint256 price)
  {
    (timestamp, price) = poolStorage.emergencyShutdown(
      lpPosition,
      feeStatus,
      emergencyShutdownData
    );
  }

  /**
   * @notice Redeem tokens after emergency shutdown
   * @return synthTokensSettled Amount of synthetic tokens liquidated
   * @return collateralSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown()
    external
    override
    isEmergencyShutdown
    nonReentrant
    returns (uint256 synthTokensSettled, uint256 collateralSettled)
  {
    address msgSender = _msgSender();
    bool isLiquidityProvider = hasRole(LIQUIDITY_PROVIDER_ROLE, msgSender);
    (synthTokensSettled, collateralSettled) = poolStorage
      .settleEmergencyShutdown(
      lpPosition,
      feeStatus,
      emergencyShutdownData,
      isLiquidityProvider,
      msgSender
    );
  }

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @notice Only the maintainer can call this function
   * @param _feeData Fee info (percentage + recipients + weigths)
   */
  function setFee(ISynthereumLiquidityPoolStorage.FeeData calldata _feeData)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(_feeData.feePercentage);
    poolStorage.setFeeRecipients(
      _feeData.feeRecipients,
      _feeData.feeProportions
    );
  }

  /**
   * @notice Update the fee percentage
   * @notice Only the maintainer can call this function
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @notice Only the maintainer can call this function
   * @param feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata feeRecipients,
    uint32[] calldata feeProportions
  ) external override onlyMaintainer nonReentrant {
    poolStorage.setFeeRecipients(feeRecipients, feeProportions);
  }

  /**
   * @notice Update the overcollateralization percentage
   * @notice Only the maintainer can call this function
   * @param _overCollateralization Overcollateralization percentage
   */
  function setOverCollateralization(uint256 _overCollateralization)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setOverCollateralization(
      liquidationData,
      FixedPoint.Unsigned(_overCollateralization)
    );
  }

  /**
   * @notice Update the liquidation reward percentage
   * @notice Only the maintainer can call this function
   * @param _liquidationReward Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationReward(uint256 _liquidationReward)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    liquidationData.setLiquidationReward(
      FixedPoint.Unsigned(_liquidationReward)
    );
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /**
   * @notice Get Synthereum finder of the pool
   * @return finder Returns finder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = poolStorage.finder;
  }

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of the Synthereum pool
   */
  function version() external view override returns (uint8 poolVersion) {
    poolVersion = poolStorage.version;
  }

  /**
   * @notice Get the collateral token
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken()
    external
    view
    override
    returns (IERC20 collateralCurrency)
  {
    collateralCurrency = poolStorage.collateralToken;
  }

  /**
   * @notice Get the synthetic token associated to this pool
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken()
    external
    view
    override
    returns (IERC20 syntheticCurrency)
  {
    syntheticCurrency = poolStorage.syntheticToken;
  }

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(poolStorage.syntheticToken)).symbol();
  }

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = poolStorage.priceIdentifier;
  }

  /**
   * @notice Return overcollateralization percentage from the storage
   * @return Overcollateralization percentage
   */
  function overCollateralization() external view override returns (uint256) {
    return poolStorage.overCollateralization.rawValue;
  }

  /**
   * @notice Returns fee percentage set by the maintainer
   * @return Fee percentage
   */
  function feePercentage() external view override returns (uint256) {
    return poolStorage.fee.feeData.feePercentage.rawValue;
  }

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigths
   */
  function feeRecipientsInfo()
    external
    view
    override
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    )
  {
    FeeData storage _feeData = poolStorage.fee.feeData;
    return (
      _feeData.feeRecipients,
      _feeData.feeProportions,
      poolStorage.fee.totalFeeProportions
    );
  }

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return Number of synthetic tokens
   */
  function totalSyntheticTokens() external view override returns (uint256) {
    return lpPosition.tokensCollateralized.rawValue;
  }

  /**
   * @notice Returns the total amount of collateral used for collateralizing tokens (users + LP)
   * @return Total collateral amount
   */
  function totalCollateralAmount() external view override returns (uint256) {
    return lpPosition.totalCollateralAmount.rawValue;
  }

  /**
   * @notice Returns the total amount of liquidity deposited in the pool, but nut used as collateral
   * @return Total available liquidity
   */
  function totalAvailableLiquidity() external view override returns (uint256) {
    return poolStorage.totalAvailableLiquidity(lpPosition, feeStatus);
  }

  /**
   * @notice Returns the total amount of fees to be withdrawn
   * @return Total fee amount
   */
  function totalFeeAmount() external view override returns (uint256) {
    return feeStatus.totalFeeAmount.rawValue;
  }

  /**
   * @notice Returns the user's fee to be withdrawn
   * @param user User's address
   * @return User's fee
   */
  function userFee(address user) external view override returns (uint256) {
    return feeStatus.feeGained[user].rawValue;
  }

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return Percentage of overcollateralization
   */
  function collateralRequirement() external view override returns (uint256) {
    return liquidationData.collateralRequirement.rawValue;
  }

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return Percentage of reward
   */
  function liquidationReward() external view override returns (uint256) {
    return liquidationData.liquidationReward.rawValue;
  }

  /**
   * @notice Returns the price of the pair at the moment of the shutdown
   * @return Price of the pair
   */
  function emergencyShutdownPrice() external view override returns (uint256) {
    return emergencyShutdownData.price.rawValue;
  }

  /**
   * @notice Returns the timestamp (unix time) at the moment of the shutdown
   * @return Timestamp
   */
  function emergencyShutdownTimestamp()
    external
    view
    override
    returns (uint256)
  {
    return emergencyShutdownData.timestamp;
  }

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage() external view override returns (bool, uint256) {
    return poolStorage.collateralCoverage(lpPosition, liquidationData);
  }

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param inputCollateral Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(uint256 inputCollateral)
    external
    view
    override
    returns (uint256 synthTokensReceived, uint256 feePaid)
  {
    (synthTokensReceived, feePaid) = poolStorage.getMintTradeInfo(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(inputCollateral)
    );
  }

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(uint256 syntheticTokens)
    external
    view
    override
    returns (uint256 collateralAmountReceived, uint256 feePaid)
  {
    (collateralAmountReceived, feePaid) = poolStorage.getRedeemTradeInfo(
      lpPosition,
      FixedPoint.Unsigned(syntheticTokens)
    );
  }

  /**
   * @notice Returns the destination synthetic tokens amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @param  destinationPool Pool in which mint the destination synthetic token
   * @return destSyntheticTokensReceived Synthetic tokens will be received from destination pool
   * @return feePaid Collateral fee will be paid
   */
  function getExchangeTradeInfo(
    uint256 syntheticTokens,
    ISynthereumLiquidityPoolGeneral destinationPool
  )
    external
    view
    override
    returns (uint256 destSyntheticTokensReceived, uint256 feePaid)
  {
    (destSyntheticTokensReceived, feePaid) = poolStorage.getExchangeTradeInfo(
      lpPosition,
      FixedPoint.Unsigned(syntheticTokens),
      destinationPool
    );
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      poolStorage.finder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}