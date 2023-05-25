// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IMonetaryPolicy.sol";

import "../lib/BlockNumber.sol";
import "../lib/MathHelper.sol";
import "../external-lib/SafeDecimalMath.sol";
import "../oracle/interfaces/IEthUsdOracle.sol";

contract MonetaryPolicyV1 is IMonetaryPolicy, BlockNumber, AccessControl {
  using SafeMath for uint256;
  using SafeDecimalMath for uint256;

  /* ========== CONSTANTS ========== */
  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant AUCTION_HOUSE_ROLE = keccak256("AUCTION_HOUSE_ROLE");
  // 0.001$ <= Target Price <= 1000$ as a basic sense check
  uint256 private constant MAX_TARGET_PRICE = 1000e27;
  uint256 private constant MIN_TARGET_PRICE = 0.001e27;

  uint256 private constant MAX_PRICE_DELTA_BOUND = 1e27;
  uint256 private constant DEFAULT_MAX_PRICE_DELTA = 4e27;

  uint256 private constant DEFAULT_MAX_ADJ_PERIOD = 1e6;
  uint256 private constant DEFAULT_MIN_ADJ_PERIOD = 2e5;
  // 150 blocks (auction duration) < T_min < T_max < 10 000 000 (~4yrs)
  uint256 private constant CAP_MAX_ADJ_PERIOD = 1e7;
  uint256 private constant CAP_MIN_ADJ_PERIOD = 150;
  /**
   * @notice The default FLOAT starting price, golden ratio
   * @dev [e27]
   */
  uint256 public constant STARTING_PRICE = 1.618033988749894848204586834e27;

  /* ========== STATE VARIABLES ========== */
  /**
   * @notice The FLOAT target price in USD.
   * @dev [e27]
   */
  uint256 public targetPrice = STARTING_PRICE;

  /**
   * @notice If dynamic pricing is enabled.
   */
  bool public dynamicPricing = true;

  /**
   * @notice Maximum price Delta of 400%
   */
  uint256 public maxPriceDelta = DEFAULT_MAX_PRICE_DELTA;

  /**
   * @notice Maximum adjustment period T_max (Blocks)
   * @dev "How long it takes us to normalise"
   * - T_max => T_min, quicker initial response with higher price changes.
   */
  uint256 public maxAdjustmentPeriod = DEFAULT_MAX_ADJ_PERIOD;

  /**
   * @notice Minimum adjustment period T_min (Blocks)
   * @dev "How quickly we respond to market price changes"
   * - Low T_min, increased tracking.
   */
  uint256 public minAdjustmentPeriod = DEFAULT_MIN_ADJ_PERIOD;

  /**
   * @notice Provides the ETH-USD exchange rate e.g. 1.5e27 would mean 1 ETH = $1.5
   * @dev [e27] decimal fixed point number
   */
  IEthUsdOracle public ethUsdOracle;

  /* ========== CONSTRUCTOR ========== */
  /**
   * @notice Construct a new Monetary Policy
   * @param _governance Governance address (can add new roles & parameter control)
   * @param _ethUsdOracle The [e27] ETH USD price feed.
   */
  constructor(address _governance, address _ethUsdOracle) {
    ethUsdOracle = IEthUsdOracle(_ethUsdOracle);

    // Roles
    _setupRole(DEFAULT_ADMIN_ROLE, _governance);
    _setupRole(GOVERNANCE_ROLE, _governance);
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernance {
    require(hasRole(GOVERNANCE_ROLE, msg.sender), "MonetaryPolicy/OnlyGovRole");
    _;
  }

  modifier onlyAuctionHouse {
    require(
      hasRole(AUCTION_HOUSE_ROLE, msg.sender),
      "MonetaryPolicy/OnlyAuctionHouse"
    );
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Consult monetary policy to get the current target price of FLOAT in ETH
   * @dev [e27]
   */
  function consult() public view override(IMonetaryPolicy) returns (uint256) {
    if (!dynamicPricing) return _toEth(STARTING_PRICE);

    return _toEth(targetPrice);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- onlyGovernance ----- */

  /**
   * @notice Updates the EthUsdOracle
   * @param _ethUsdOracle The address of the ETH-USD price oracle.
   */
  function setEthUsdOracle(address _ethUsdOracle) external onlyGovernance {
    require(_ethUsdOracle != address(0), "MonetaryPolicyV1/ValidAddress");
    ethUsdOracle = IEthUsdOracle(_ethUsdOracle);
  }

  /**
   * @notice Set the target price of FLOAT
   * @param _targetPrice [e27]
   */
  function setTargetPrice(uint256 _targetPrice) external onlyGovernance {
    require(_targetPrice <= MAX_TARGET_PRICE, "MonetaryPolicyV1/MaxTarget");
    require(_targetPrice >= MIN_TARGET_PRICE, "MonetaryPolicyV1/MinTarget");
    targetPrice = _targetPrice;
  }

  /**
   * @notice Allows dynamic pricing to be turned on / off.
   */
  function setDynamicPricing(bool _dynamicPricing) external onlyGovernance {
    dynamicPricing = _dynamicPricing;
  }

  /**
   * @notice Allows monetary policy parameters to be adjusted.
   */
  function setPolicyParameters(
    uint256 _minAdjustmentPeriod,
    uint256 _maxAdjustmentPeriod,
    uint256 _maxPriceDelta
  ) external onlyGovernance {
    require(
      _minAdjustmentPeriod < _maxAdjustmentPeriod,
      "MonetaryPolicyV1/MinAdjLTMaxAdj"
    );
    require(
      _maxAdjustmentPeriod <= CAP_MAX_ADJ_PERIOD,
      "MonetaryPolicyV1/MaxAdj"
    );
    require(
      _minAdjustmentPeriod >= CAP_MIN_ADJ_PERIOD,
      "MonetaryPolicyV1/MinAdj"
    );
    require(
      _maxPriceDelta >= MAX_PRICE_DELTA_BOUND,
      "MonetaryPolicyV1/MaxDeltaBound"
    );
    minAdjustmentPeriod = _minAdjustmentPeriod;
    maxAdjustmentPeriod = _maxAdjustmentPeriod;
    maxPriceDelta = _maxPriceDelta;
  }

  /* ----- onlyAuctionHouse ----- */

  /**
   * @notice Updates with previous auctions result
   * @dev future:param round Round number
   * @param lastAuctionBlock The last time an auction started.
   * @param floatMarketPriceInEth [e27] The current float market price (ETH)
   * @param basketFactor [e27] The basket factor given the prior target price
   * @return targetPriceInEth [e27]
   */
  function updateGivenAuctionResults(
    uint256,
    uint256 lastAuctionBlock,
    uint256 floatMarketPriceInEth,
    uint256 basketFactor
  ) external override(IMonetaryPolicy) onlyAuctionHouse returns (uint256) {
    // Exit early if this is the first auction
    if (lastAuctionBlock == 0) {
      return consult();
    }

    return
      _updateTargetPrice(lastAuctionBlock, floatMarketPriceInEth, basketFactor);
  }

  /**
   * @dev Converts [e27] USD price, to an [e27] ETH Price
   */
  function _toEth(uint256 price) internal view returns (uint256) {
    uint256 ethInUsd = ethUsdOracle.consult();
    return price.divideDecimalRoundPrecise(ethInUsd);
  }

  /**
   * @dev Updates the $ valued target price, returns the eth valued target price.
   */
  function _updateTargetPrice(
    uint256 _lastAuctionBlock,
    uint256 _floatMarketPriceInEth,
    uint256 _basketFactor
  ) internal returns (uint256) {
    // _toEth pulled out as we do a _fromEth later.
    uint256 ethInUsd = ethUsdOracle.consult();
    uint256 priorTargetPriceInEth =
      targetPrice.divideDecimalRoundPrecise(ethInUsd);

    // Check if basket and FLOAT are moving the same direction
    bool basketFactorDown = _basketFactor < SafeDecimalMath.PRECISE_UNIT;
    bool floatDown = _floatMarketPriceInEth < priorTargetPriceInEth;
    if (basketFactorDown != floatDown) {
      return priorTargetPriceInEth;
    }

    // N.B: block number will always be >= _lastAuctionBlock
    uint256 auctionTimePeriod = _blockNumber().sub(_lastAuctionBlock);

    uint256 normDelta =
      _normalisedDelta(_floatMarketPriceInEth, priorTargetPriceInEth);
    uint256 adjustmentPeriod = _adjustmentPeriod(normDelta);

    // [e27]
    uint256 basketFactorDiff =
      MathHelper.diff(_basketFactor, SafeDecimalMath.PRECISE_UNIT);

    uint256 targetChange =
      priorTargetPriceInEth.multiplyDecimalRoundPrecise(
        basketFactorDiff.mul(auctionTimePeriod).div(adjustmentPeriod)
      );

    // If we have got this far, then we know that market and basket are
    // in the same direction, so basketFactor can be used to choose direction.
    uint256 targetPriceInEth =
      basketFactorDown
        ? priorTargetPriceInEth.sub(targetChange)
        : priorTargetPriceInEth.add(targetChange);

    targetPrice = targetPriceInEth.multiplyDecimalRoundPrecise(ethInUsd);

    return targetPriceInEth;
  }

  function _adjustmentPeriod(uint256 _normDelta)
    internal
    view
    returns (uint256)
  {
    // calculate T, 'the adjustment period', similar to "lookback" as it controls the length of the tail
    // T = T_max - d (T_max - T_min).
    //   = d * T_min + T_max - d * T_max
    // TBC: This doesn't need safety checks
    // T_min <= T <= T_max
    return
      minAdjustmentPeriod
        .multiplyDecimalRoundPrecise(_normDelta)
        .add(maxAdjustmentPeriod)
        .sub(maxAdjustmentPeriod.multiplyDecimalRoundPrecise(_normDelta));
  }

  /**
   * @notice Obtain normalised delta between market and target price
   */
  function _normalisedDelta(
    uint256 _floatMarketPriceInEth,
    uint256 _priorTargetPriceInEth
  ) internal view returns (uint256) {
    uint256 delta =
      MathHelper.diff(_floatMarketPriceInEth, _priorTargetPriceInEth);
    uint256 scaledDelta =
      delta.divideDecimalRoundPrecise(_priorTargetPriceInEth);

    // Invert delta if contraction to flip curve from concave increasing to convex decreasing
    // Also allows for a greater response in expansions than contractions.
    if (_floatMarketPriceInEth < _priorTargetPriceInEth) {
      scaledDelta = scaledDelta.divideDecimalRoundPrecise(
        SafeDecimalMath.PRECISE_UNIT.sub(scaledDelta)
      );
    }

    // Normalise delta based on Dmax -> 0 <= d <= X
    uint256 normDelta = scaledDelta.divideDecimalRoundPrecise(maxPriceDelta);

    // Cap normalised delta 0 <= d <= 1
    if (normDelta > SafeDecimalMath.PRECISE_UNIT) {
      normDelta = SafeDecimalMath.PRECISE_UNIT;
    }

    return normDelta;
  }
}