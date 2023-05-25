// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./Staged.sol";
import "./AuctionHouseMath.sol";

import "./interfaces/IAuctionHouse.sol";

import "../funds/interfaces/basket/IBasketReader.sol";
import "../oracle/interfaces/ITwap.sol";
import "../policy/interfaces/IMonetaryPolicy.sol";
import "../tokens/interfaces/ISupplyControlledERC20.sol";

import "../lib/BasisMath.sol";
import "../lib/BlockNumber.sol";
import "../lib/Recoverable.sol";
import "../external-lib/SafeDecimalMath.sol";
import "../tokens/SafeSupplyControlledERC20.sol";

/**
 * @title Float Protocol Auction House
 * @notice The contract used to sell or buy FLOAT
 * @dev This contract does not store any assets, except for protocol fees, hence
 * it implements an asset recovery functionality (Recoverable).
 */
contract AuctionHouse is
  IAuctionHouse,
  BlockNumber,
  AuctionHouseMath,
  AccessControl,
  Staged,
  Recoverable
{
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for ISupplyControlledERC20;
  using SafeSupplyControlledERC20 for ISupplyControlledERC20;
  using BasisMath for uint256;

  /* ========== CONSTANTS ========== */
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

  IERC20 internal immutable weth;
  ISupplyControlledERC20 internal immutable bank;
  ISupplyControlledERC20 internal immutable float;
  IBasketReader internal immutable basket;

  /* ========== STATE VARIABLES ========== */
  // Monetary Policy Contract that decides the target price
  IMonetaryPolicy internal monetaryPolicy;
  // Provides the BANK-ETH Time Weighted Average Price (TWAP) [e27]
  ITwap internal bankEthOracle;
  // Provides the FLOAT-ETH Time Weighted Average Price (TWAP) [e27]
  ITwap internal floatEthOracle;

  /// @inheritdoc IAuctionHouseState
  uint16 public override buffer = 10_00; // 10% default

  /// @inheritdoc IAuctionHouseState
  uint16 public override protocolFee = 5_00; // 5% / 500 bps

  /// @inheritdoc IAuctionHouseState
  uint32 public override allowanceCap = 10_00; // 10% / 1000 bps

  /// @inheritdoc IAuctionHouseVariables
  uint64 public override round;

  /**
   * @notice Allows for monetary policy updates to be enabled and disabled.
   */
  bool public shouldUpdatePolicy = true;

  /**
   * Note that we choose to freeze all price values at the start of an auction.
   * These values are stale _by design_. The burden of price checking
   * is moved to the arbitrager, already vital for them to make a profit.
   * We don't mind these values being out of date, as we start the auctions from a position generously in favour of the protocol (assuming our target price is correct). If these market values are stale, then profit opportunity will start earlier / later, and hence close out a mispriced auction early.
   * We also start the auctions at `buffer`% of the price.
   */

  /// @inheritdoc IAuctionHouseVariables
  mapping(uint64 => Auction) public override auctions;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    // Dependencies
    address _weth,
    address _bank,
    address _float,
    address _basket,
    address _monetaryPolicy,
    address _gov,
    address _bankEthOracle,
    address _floatEthOracle,
    // Parameters
    uint16 _auctionDuration,
    uint32 _auctionCooldown,
    uint256 _firstAuctionBlock
  ) Staged(_auctionDuration, _auctionCooldown, _firstAuctionBlock) {
    // Tokens
    weth = IERC20(_weth);
    bank = ISupplyControlledERC20(_bank);
    float = ISupplyControlledERC20(_float);

    // Basket
    basket = IBasketReader(_basket);

    // Monetary Policy
    monetaryPolicy = IMonetaryPolicy(_monetaryPolicy);
    floatEthOracle = ITwap(_floatEthOracle);
    bankEthOracle = ITwap(_bankEthOracle);

    emit ModifyParameters("monetaryPolicy", _monetaryPolicy);
    emit ModifyParameters("floatEthOracle", _floatEthOracle);
    emit ModifyParameters("bankEthOracle", _bankEthOracle);

    emit ModifyParameters("auctionDuration", _auctionDuration);
    emit ModifyParameters("auctionCooldown", _auctionCooldown);
    emit ModifyParameters("lastAuctionBlock", lastAuctionBlock);
    emit ModifyParameters("buffer", buffer);
    emit ModifyParameters("protocolFee", protocolFee);
    emit ModifyParameters("allowanceCap", allowanceCap);

    // Roles
    _setupRole(DEFAULT_ADMIN_ROLE, _gov);
    _setupRole(GOVERNANCE_ROLE, _gov);
    _setupRole(RECOVER_ROLE, _gov);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(
      hasRole(GOVERNANCE_ROLE, _msgSender()),
      "AuctionHouse/GovernanceRole"
    );
    _;
  }

  modifier inExpansion {
    require(
      latestAuction().stabilisationCase == Cases.Up ||
        latestAuction().stabilisationCase == Cases.Restock,
      "AuctionHouse/NotInExpansion"
    );
    _;
  }

  modifier inContraction {
    require(
      latestAuction().stabilisationCase == Cases.Confidence ||
        latestAuction().stabilisationCase == Cases.Down,
      "AuctionHouse/NotInContraction"
    );
    _;
  }

  /* ========== VIEWS ========== */

  /// @inheritdoc IAuctionHouseDerivedState
  function price()
    public
    view
    override(IAuctionHouseDerivedState)
    returns (uint256 wethPrice, uint256 bankPrice)
  {
    Auction memory _latestAuction = latestAuction();
    uint256 _step = step();

    wethPrice = lerp(
      _latestAuction.startWethPrice,
      _latestAuction.endWethPrice,
      _step,
      auctionDuration
    );
    bankPrice = lerp(
      _latestAuction.startBankPrice,
      _latestAuction.endBankPrice,
      _step,
      auctionDuration
    );
    return (wethPrice, bankPrice);
  }

  /// @inheritdoc IAuctionHouseDerivedState
  function step()
    public
    view
    override(IAuctionHouseDerivedState)
    atStage(Stages.AuctionActive)
    returns (uint256)
  {
    // .sub is unnecessary here - block number >= lastAuctionBlock.
    return _blockNumber() - lastAuctionBlock;
  }

  function _startPrice(
    bool expansion,
    Cases stabilisationCase,
    uint256 targetFloatInEth,
    uint256 marketFloatInEth,
    uint256 bankInEth,
    uint256 basketFactor
  ) internal view returns (uint256 wethStart, uint256 bankStart) {
    uint256 bufferedMarketPrice =
      _bufferedMarketPrice(expansion, marketFloatInEth);

    if (stabilisationCase == Cases.Up) {
      uint256 bankProportion =
        bufferedMarketPrice.sub(targetFloatInEth).divideDecimalRoundPrecise(
          bankInEth
        );

      return (targetFloatInEth, bankProportion);
    }

    if (
      stabilisationCase == Cases.Restock ||
      stabilisationCase == Cases.Confidence
    ) {
      return (bufferedMarketPrice, 0);
    }

    assert(stabilisationCase == Cases.Down);
    assert(basketFactor < SafeDecimalMath.PRECISE_UNIT);
    uint256 invertedBasketFactor =
      SafeDecimalMath.PRECISE_UNIT.sub(basketFactor);

    uint256 basketFactorAdjustedEth =
      bufferedMarketPrice.multiplyDecimalRoundPrecise(basketFactor);

    // Note that the PRECISE_UNIT factors itself out
    uint256 basketFactorAdjustedBank =
      bufferedMarketPrice.mul(invertedBasketFactor).div(bankInEth);
    return (basketFactorAdjustedEth, basketFactorAdjustedBank);
  }

  function _endPrice(
    Cases stabilisationCase,
    uint256 targetFloatInEth,
    uint256 bankInEth,
    uint256 basketFactor
  ) internal pure returns (uint256 wethEnd, uint256 bankEnd) {
    if (stabilisationCase == Cases.Down) {
      assert(basketFactor < SafeDecimalMath.PRECISE_UNIT);
      uint256 invertedBasketFactor =
        SafeDecimalMath.PRECISE_UNIT.sub(basketFactor);

      uint256 basketFactorAdjustedEth =
        targetFloatInEth.multiplyDecimalRoundPrecise(basketFactor);

      // Note that the PRECISE_UNIT factors itself out.
      uint256 basketFactorAdjustedBank =
        targetFloatInEth.mul(invertedBasketFactor).div(bankInEth);
      return (basketFactorAdjustedEth, basketFactorAdjustedBank);
    }

    return (targetFloatInEth, 0);
  }

  /// @inheritdoc IAuctionHouseDerivedState
  function latestAuction()
    public
    view
    override(IAuctionHouseDerivedState)
    returns (Auction memory)
  {
    return auctions[round];
  }

  /// @dev Returns a buffered [e27] market price, note that buffer is still [e18], so can use divideDecimal.
  function _bufferedMarketPrice(bool expansion, uint256 marketPrice)
    internal
    view
    returns (uint256)
  {
    uint256 factor =
      expansion
        ? BasisMath.FULL_PERCENT.add(buffer)
        : BasisMath.FULL_PERCENT.sub(buffer);
    return marketPrice.percentageOf(factor);
  }

  /// @dev Calculates the current case based on if we're expanding and basket factor.
  function _currentCase(bool expansion, uint256 basketFactor)
    internal
    pure
    returns (Cases)
  {
    bool underlyingDemand = basketFactor >= SafeDecimalMath.PRECISE_UNIT;

    if (expansion) {
      return underlyingDemand ? Cases.Up : Cases.Restock;
    }

    return underlyingDemand ? Cases.Confidence : Cases.Down;
  }

  /* |||||||||| AuctionPending |||||||||| */

  // solhint-disable function-max-lines
  /// @inheritdoc IAuctionHouseActions
  function start()
    external
    override(IAuctionHouseActions)
    timedTransition
    atStage(Stages.AuctionPending)
    returns (uint64 newRound)
  {
    // Check we have up to date oracles, this also ensures we don't have
    // auctions too close together (reverts based upon timeElapsed < periodSize).
    bankEthOracle.update(address(bank), address(weth));
    floatEthOracle.update(address(float), address(weth));

    // [e27]
    uint256 frozenBankInEth =
      bankEthOracle.consult(
        address(bank),
        SafeDecimalMath.PRECISE_UNIT,
        address(weth)
      );
    // [e27]
    uint256 frozenFloatInEth =
      floatEthOracle.consult(
        address(float),
        SafeDecimalMath.PRECISE_UNIT,
        address(weth)
      );

    // Update Monetary Policy with previous auction results
    if (round != 0 && shouldUpdatePolicy) {
      uint256 oldTargetPriceInEth = monetaryPolicy.consult();
      uint256 oldBasketFactor = basket.getBasketFactor(oldTargetPriceInEth);

      monetaryPolicy.updateGivenAuctionResults(
        round,
        lastAuctionBlock,
        frozenFloatInEth,
        oldBasketFactor
      );
    }

    // Round only increments by one on start, given auction period of restriction of 150 blocks
    // this means we'd need 2**64 / 150 blocks or ~3.7 lifetimes of the universe to overflow.
    // Likely, we'd have upgraded the contract by this point.
    round++;

    // Calculate target price [e27]
    uint256 frozenTargetPriceInEth = monetaryPolicy.consult();

    // STC: Pull out to ValidateOracles
    require(frozenTargetPriceInEth != 0, "AuctionHouse/TargetSenseCheck");
    require(frozenBankInEth != 0, "AuctionHouse/BankSenseCheck");
    require(frozenFloatInEth != 0, "AuctionHouse/FloatSenseCheck");
    uint256 basketFactor = basket.getBasketFactor(frozenTargetPriceInEth);

    bool expansion = frozenFloatInEth >= frozenTargetPriceInEth;
    Cases stabilisationCase = _currentCase(expansion, basketFactor);

    // Calculate Auction Price points
    (uint256 wethStart, uint256 bankStart) =
      _startPrice(
        expansion,
        stabilisationCase,
        frozenTargetPriceInEth,
        frozenFloatInEth,
        frozenBankInEth,
        basketFactor
      );

    (uint256 wethEnd, uint256 bankEnd) =
      _endPrice(
        stabilisationCase,
        frozenTargetPriceInEth,
        frozenBankInEth,
        basketFactor
      );

    // Calculate Allowance
    uint256 allowance =
      AuctionHouseMath.allowance(
        expansion,
        allowanceCap,
        float.totalSupply(),
        frozenFloatInEth,
        frozenTargetPriceInEth
      );

    require(allowance != 0, "AuctionHouse/NoAllowance");

    auctions[round].stabilisationCase = stabilisationCase;
    auctions[round].targetFloatInEth = frozenTargetPriceInEth;
    auctions[round].marketFloatInEth = frozenFloatInEth;
    auctions[round].bankInEth = frozenBankInEth;

    auctions[round].basketFactor = basketFactor;
    auctions[round].allowance = allowance;

    auctions[round].startWethPrice = wethStart;
    auctions[round].startBankPrice = bankStart;
    auctions[round].endWethPrice = wethEnd;
    auctions[round].endBankPrice = bankEnd;

    lastAuctionBlock = _blockNumber();
    _setStage(Stages.AuctionActive);

    emit NewAuction(round, allowance, frozenTargetPriceInEth, lastAuctionBlock);

    return round;
  }

  // solhint-enable function-max-lines

  /* |||||||||| AuctionActive |||||||||| */

  function _updateDelta(uint256 floatDelta) internal {
    Auction memory _currentAuction = latestAuction();

    require(
      floatDelta <= _currentAuction.allowance.sub(_currentAuction.delta),
      "AuctionHouse/WithinAllowedDelta"
    );

    auctions[round].delta = _currentAuction.delta.add(floatDelta);
  }

  /* |||||||||| AuctionActive:inExpansion |||||||||| */

  /// @inheritdoc IAuctionHouseActions
  function buy(
    uint256 wethInMax,
    uint256 bankInMax,
    uint256 floatOutMin,
    address to,
    uint256 deadline
  )
    external
    override(IAuctionHouseActions)
    timedTransition
    atStage(Stages.AuctionActive)
    inExpansion
    returns (
      uint256 usedWethIn,
      uint256 usedBankIn,
      uint256 usedFloatOut
    )
  {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "AuctionHouse/TransactionTooOld");

    (uint256 wethPrice, uint256 bankPrice) = price();

    usedFloatOut = Math.min(
      wethInMax.divideDecimalRoundPrecise(wethPrice),
      bankPrice == 0
        ? type(uint256).max
        : bankInMax.divideDecimalRoundPrecise(bankPrice)
    );

    require(usedFloatOut != 0, "AuctionHouse/ZeroFloatBought");
    require(usedFloatOut >= floatOutMin, "AuctionHouse/RequestedTooMuch");

    usedWethIn = wethPrice.multiplyDecimalRoundPrecise(usedFloatOut);
    usedBankIn = bankPrice.multiplyDecimalRoundPrecise(usedFloatOut);

    require(wethInMax >= usedWethIn, "AuctionHouse/MinimumWeth");
    require(bankInMax >= usedBankIn, "AuctionHouse/MinimumBank");

    _updateDelta(usedFloatOut);

    emit Buy(round, _msgSender(), usedWethIn, usedBankIn, usedFloatOut);

    _interactBuy(usedWethIn, usedBankIn, usedFloatOut, to);

    return (usedWethIn, usedBankIn, usedFloatOut);
  }

  function _interactBuy(
    uint256 usedWethIn,
    uint256 usedBankIn,
    uint256 usedFloatOut,
    address to
  ) internal {
    weth.safeTransferFrom(_msgSender(), address(basket), usedWethIn);

    if (usedBankIn != 0) {
      (uint256 bankToSave, uint256 bankToBurn) =
        usedBankIn.splitBy(protocolFee);

      bank.safeTransferFrom(_msgSender(), address(this), bankToSave);
      bank.safeBurnFrom(_msgSender(), bankToBurn);
    }

    float.safeMint(to, usedFloatOut);
  }

  /* |||||||||| AuctionActive:inContraction |||||||||| */

  /// @inheritdoc IAuctionHouseActions
  function sell(
    uint256 floatIn,
    uint256 wethOutMin,
    uint256 bankOutMin,
    address to,
    uint256 deadline
  )
    external
    override(IAuctionHouseActions)
    timedTransition
    atStage(Stages.AuctionActive)
    inContraction
    returns (
      uint256 usedfloatIn,
      uint256 usedWethOut,
      uint256 usedBankOut
    )
  {
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= deadline, "AuctionHouse/TransactionTooOld");
    require(floatIn != 0, "AuctionHouse/ZeroFloatSold");

    (uint256 wethPrice, uint256 bankPrice) = price();

    usedWethOut = wethPrice.multiplyDecimalRoundPrecise(floatIn);
    usedBankOut = bankPrice.multiplyDecimalRoundPrecise(floatIn);

    require(wethOutMin <= usedWethOut, "AuctionHouse/ExpectedTooMuchWeth");
    require(bankOutMin <= usedBankOut, "AuctionHouse/ExpectedTooMuchBank");

    _updateDelta(floatIn);

    emit Sell(round, _msgSender(), floatIn, usedWethOut, usedBankOut);

    _interactSell(floatIn, usedWethOut, usedBankOut, to);

    return (floatIn, usedWethOut, usedBankOut);
  }

  function _interactSell(
    uint256 floatIn,
    uint256 usedWethOut,
    uint256 usedBankOut,
    address to
  ) internal {
    float.safeBurnFrom(_msgSender(), floatIn);

    if (usedWethOut != 0) {
      weth.safeTransferFrom(address(basket), to, usedWethOut);
    }

    if (usedBankOut != 0) {
      // STC: Maximum mint checks relative to allowance
      bank.safeMint(to, usedBankOut);
    }
  }

  /* |||||||||| AuctionCooldown, AuctionPending, AuctionActive |||||||||| */

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /// @inheritdoc IAuctionHouseGovernedActions
  function modifyParameters(bytes32 parameter, uint256 data)
    external
    override(IAuctionHouseGovernedActions)
    onlyGovernance
  {
    if (parameter == "auctionDuration") {
      require(data <= type(uint16).max, "AuctionHouse/ModADMax");
      require(data != 0, "AuctionHouse/ModADZero");
      auctionDuration = uint16(data);
    } else if (parameter == "auctionCooldown") {
      require(data <= type(uint32).max, "AuctionHouse/ModCMax");
      auctionCooldown = uint32(data);
    } else if (parameter == "buffer") {
      // 0% <= buffer <= 1000%
      require(data <= 10 * BasisMath.FULL_PERCENT, "AuctionHouse/ModBMax");
      buffer = uint16(data);
    } else if (parameter == "protocolFee") {
      // 0% <= protocolFee <= 100%
      require(data <= BasisMath.FULL_PERCENT, "AuctionHouse/ModPFMax");
      protocolFee = uint16(data);
    } else if (parameter == "allowanceCap") {
      // 0% < allowanceCap <= N ~ 1_000%
      require(data <= type(uint32).max, "AuctionHouse/ModACMax");
      require(data != 0, "AuctionHouse/ModACMin");
      allowanceCap = uint32(data);
    } else if (parameter == "shouldUpdatePolicy") {
      require(data == 1 || data == 0, "AuctionHouse/ModUP");
      shouldUpdatePolicy = data == 1;
    } else if (parameter == "lastAuctionBlock") {
      // We wouldn't want to disable auctions for more than ~4.3 weeks
      // A longer period should result in a "burnt" auction house and redeploy.
      require(data <= block.number + 2e5, "AuctionHouse/ModLABMax");
      require(data != 0, "AuctionHouse/ModLABMin");
      // Can be used to pause auctions if set in the future.
      lastAuctionBlock = data;
    } else revert("AuctionHouse/InvalidParameter");

    emit ModifyParameters(parameter, data);
  }

  /// @inheritdoc IAuctionHouseGovernedActions
  function modifyParameters(bytes32 parameter, address data)
    external
    override(IAuctionHouseGovernedActions)
    onlyGovernance
  {
    if (parameter == "monetaryPolicy") {
      // STC: Sense check
      monetaryPolicy = IMonetaryPolicy(data);
    } else if (parameter == "bankEthOracle") {
      // STC: Sense check
      bankEthOracle = ITwap(data);
    } else if (parameter == "floatEthOracle") {
      // STC: Sense check
      floatEthOracle = ITwap(data);
    } else revert("AuctionHouse/InvalidParameter");

    emit ModifyParameters(parameter, data);
  }
}