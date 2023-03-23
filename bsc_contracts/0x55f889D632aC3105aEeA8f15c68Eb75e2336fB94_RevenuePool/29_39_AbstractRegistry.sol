// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IRegistry.sol";
import "./IFee.sol";
import "../libs/Errors.sol";
import "../libs/math/FixedPoint.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract AbstractRegistry is
  IRegistry,
  AccessControlUpgradeable,
  OwnableUpgradeable
{
  using FixedPoint for uint256;
  using FixedPoint for int256;
  using SafeCast for uint256;
  using SafeCast for int256;

  bytes32 public constant APPROVED_ROLE = keccak256("APPROVED_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
  bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

  uint128 public salt;

  // constant subject to governance update
  uint16 public maxOpenTradesPerPriceId;
  uint16 public maxOpenTradesPerUser;
  uint64 public liquidationPenalty;
  uint64 public feeFactor;
  uint128 public maxMarginPerUser;
  uint128 public minPositionPerTrade;
  uint128 public maxPercentagePnLFactor;
  uint128 public stopFee;
  uint128 public fee;

  // optional constant
  uint128 public maxPercentagePnLCap;
  uint128 public maxPercentagePnLFloor;

  // variable
  uint128 public minCollateral;

  // constant subject to governance update
  mapping(bytes32 => bool) public approvedPriceId;
  mapping(bytes32 => uint128) public maxLeveragePerPriceId;
  mapping(bytes32 => uint128) public minLeveragePerPriceId;
  mapping(bytes32 => uint64) public liquidationThresholdPerPriceId;
  mapping(bytes32 => uint128) public impactRefDepthLongPerPriceId;
  mapping(bytes32 => uint128) public impactRefDepthShortPerPriceId;

  // dynamic variable
  mapping(bytes32 => Trade) internal __openTradeByOrderHash;

  mapping(address => mapping(bytes32 => uint128))
    public openTradesPerPriceIdCount;
  mapping(address => uint128) public openTradesPerUserCount;
  mapping(address => uint128) public totalMarginPerUser;

  mapping(bytes32 => uint128) public totalLongPerPriceId;
  mapping(bytes32 => uint128) public totalShortPerPriceId;

  event ApprovedPriceIdEvent(bytes32 priceId, bool approved);
  event SetMaxOpenTradesPerPriceIdEvent(uint256 maxOpenTradesPerPriceId);
  event SetMaxOpenTradesPerUserEvent(uint256 maxOpenTradesPerUser);
  event SetMaxMarginPerUserEvent(uint256 maxMarginPerUser);
  event SetMinPositionPerTradeEvent(uint256 minPositionPerTrade);
  event SetLiquidationThresholdEvent(
    bytes32 priceId,
    uint256 liquidationThreshold
  );
  event SetLiquidationPenaltyEvent(uint256 liquidationPenalty);
  event SetMaxLeverageEvent(bytes32 priceId, uint256 maxLeverage);
  event SetMinLeverageEvent(bytes32 priceId, uint256 minLeverage);
  event SetMaxPercentagePnLFactorEvent(uint256 maxPercentagePnLFactor);
  event SetMaxPercentagePnLCapEvent(uint256 maxPercentagePnLCap);
  event SetMaxPercentagePnLFloorEvent(uint256 maxPercentagePnLFloor);
  event SetFeeEvent(uint256 fee);
  event SetFeeFactorEvent(uint256 feeFactor);
  event SetImpactRefDepthLongEvent(bytes32 priceId, uint256 impactRefDepthLong);
  event SetImpactRefDepthShortEvent(
    bytes32 priceId,
    uint256 impactRefDepthShort
  );
  event SetStopFeeEvent(uint256 stopFee);

  function __AbstractRegistry_init(
    address owner,
    uint16 _maxOpenTradesPerPriceId,
    uint16 _maxOpenTradesPerUser,
    uint128 _maxMarginPerUser,
    uint128 _minPositionPerTrade,
    uint64 _liquidationPenalty,
    uint128 _maxPercentagePnLFactor,
    uint128 _stopFee,
    uint128 _fee
  ) internal onlyInitializing {
    __AccessControl_init();
    __Ownable_init();
    _transferOwnership(owner);
    _grantRole(DEFAULT_ADMIN_ROLE, owner);
    _grantRole(UPDATER_ROLE, owner);
    maxOpenTradesPerPriceId = _maxOpenTradesPerPriceId;
    maxOpenTradesPerUser = _maxOpenTradesPerUser;
    maxMarginPerUser = _maxMarginPerUser;
    minPositionPerTrade = _minPositionPerTrade;
    liquidationPenalty = _liquidationPenalty;
    maxPercentagePnLFactor = _maxPercentagePnLFactor;
    stopFee = _stopFee;
    fee = _fee;

    maxPercentagePnLCap = type(uint128).max;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier onlyApprovedPriceId(bytes32 priceId) {
    _require(approvedPriceId[priceId], Errors.APPROVED_PRICE_ID_ONLY);
    _;
  }

  // external functions

  function isLiquidator(address user) external view override returns (bool) {
    return hasRole(LIQUIDATOR_ROLE, user);
  }

  function openTradeByOrderHash(
    bytes32 orderHash
  ) external view returns (Trade memory) {
    return _openTradeByOrderHash(orderHash);
  }

  function UncheckedOpenTradeByOrderHash(
    bytes32 orderHash
  ) external view returns (Trade memory) {
    return __openTradeByOrderHash[orderHash];
  }

  function getFee() external view virtual returns (uint256) {
    return fee;
  }

  function getSlippage(
    bytes32 priceId,
    bool isBuy,
    uint128 price,
    uint128 position
  ) external view override returns (uint128) {
    return _getSlippage(priceId, isBuy, price, position);
  }

  // governance functions

  function setMaxOpenTradesPerPriceId(
    uint16 _maxOpenTradesPerPriceId
  ) external onlyOwner {
    maxOpenTradesPerPriceId = _maxOpenTradesPerPriceId;
    emit SetMaxOpenTradesPerPriceIdEvent(maxOpenTradesPerPriceId);
  }

  function setMaxOpenTradesPerUser(
    uint16 _maxOpenTradesPerUser
  ) external onlyOwner {
    maxOpenTradesPerUser = _maxOpenTradesPerUser;
    emit SetMaxOpenTradesPerUserEvent(maxOpenTradesPerUser);
  }

  function setMaxMarginPerUser(uint128 _maxMarginPerUser) external onlyOwner {
    maxMarginPerUser = _maxMarginPerUser;
    emit SetMaxMarginPerUserEvent(maxMarginPerUser);
  }

  function setMinPositionPerTrade(
    uint128 _minPositionPerTrade
  ) external onlyOwner {
    minPositionPerTrade = _minPositionPerTrade;
    emit SetMinPositionPerTradeEvent(minPositionPerTrade);
  }

  function setApprovedPriceId(
    bytes32 priceId,
    bool approved
  ) external onlyOwner {
    approvedPriceId[priceId] = approved;
    emit ApprovedPriceIdEvent(priceId, approved);
  }

  function setLiquidationThresholdPerPriceId(
    bytes32 priceId,
    uint64 liquidationThreshold
  ) external onlyOwner {
    liquidationThresholdPerPriceId[priceId] = liquidationThreshold;
    emit SetLiquidationThresholdEvent(priceId, liquidationThreshold);
  }

  function setLiquidationPenalty(
    uint64 _liquidationPenalty
  ) external onlyOwner {
    liquidationPenalty = _liquidationPenalty;
    emit SetLiquidationPenaltyEvent(liquidationPenalty);
  }

  function setMaxLeveragePerPriceId(
    bytes32 priceId,
    uint128 maxLeverage
  ) external onlyOwner {
    _require(
      maxLeverage >= minLeveragePerPriceId[priceId],
      Errors.MAX_SMALLER_THAN_MIN
    );
    maxLeveragePerPriceId[priceId] = maxLeverage;
    emit SetMaxLeverageEvent(priceId, maxLeverage);
  }

  function setMinLeveragePerPriceId(
    bytes32 priceId,
    uint128 minLeverage
  ) external onlyOwner {
    _require(
      minLeverage <= maxLeveragePerPriceId[priceId],
      Errors.MIN_BIGGER_THAN_MAX
    );
    _require(
      minLeverage >= liquidationThresholdPerPriceId[priceId],
      Errors.MIN_SMALLER_THAN_THRESHOLD
    );
    minLeveragePerPriceId[priceId] = minLeverage;
    emit SetMinLeverageEvent(priceId, minLeverage);
  }

  function setMaxPercentagePnLFloor(
    uint128 _maxPercentagePnLFloor
  ) external onlyOwner {
    _require(
      _maxPercentagePnLFloor <= maxPercentagePnLCap,
      Errors.MIN_BIGGER_THAN_MAX
    );
    maxPercentagePnLFloor = _maxPercentagePnLFloor;
    emit SetMaxPercentagePnLFloorEvent(maxPercentagePnLFloor);
  }

  function setMaxPercentagePnLCap(
    uint128 _maxPercentagePnLCap
  ) external onlyOwner {
    _require(
      _maxPercentagePnLCap >= maxPercentagePnLFloor,
      Errors.MAX_SMALLER_THAN_MIN
    );
    maxPercentagePnLCap = _maxPercentagePnLCap;
    emit SetMaxPercentagePnLCapEvent(maxPercentagePnLCap);
  }

  function setMaxPercentagePnLFactor(
    uint128 _maxPercentagePnLFactor
  ) external onlyOwner {
    maxPercentagePnLFactor = _maxPercentagePnLFactor;
    emit SetMaxPercentagePnLFactorEvent(maxPercentagePnLFactor);
  }

  function setFee(uint128 _fee) external onlyOwner {
    fee = _fee;
    emit SetFeeEvent(fee);
  }

  function setFeeFactor(uint64 _feeFactor) external onlyOwner {
    _require(_feeFactor >= 0 && _feeFactor <= 1e18, Errors.INVALID_FEE_FACTOR);
    feeFactor = _feeFactor;
    emit SetFeeFactorEvent(feeFactor);
  }

  function setStopFee(uint128 _stopFee) external onlyOwner {
    stopFee = _stopFee;
    emit SetStopFeeEvent(stopFee);
  }

  // priviledged functions

  function setImpactRefDepthLongPerPriceId(
    bytes32 priceId,
    uint128 impactRefDepthLong
  ) external onlyRole(UPDATER_ROLE) {
    impactRefDepthLongPerPriceId[priceId] = impactRefDepthLong;
    emit SetImpactRefDepthLongEvent(priceId, impactRefDepthLong);
  }

  function setImpactRefDepthShortPerPriceId(
    bytes32 priceId,
    uint128 impactRefDepthShort
  ) external onlyRole(UPDATER_ROLE) {
    impactRefDepthShortPerPriceId[priceId] = impactRefDepthShort;
    emit SetImpactRefDepthShortEvent(priceId, impactRefDepthShort);
  }

  // internal functions

  function _openTradeByOrderHash(
    bytes32 orderHash
  ) internal view returns (Trade memory t) {
    t = __openTradeByOrderHash[orderHash];
    _require(t.user != address(0x0), Errors.ORDER_NOT_FOUND);
  }

  function _getSlippage(
    bytes32 priceId,
    bool isBuy,
    uint128 price,
    uint128 position
  ) internal view returns (uint128) {
    uint256 impact = (
      uint256(
        isBuy ? totalLongPerPriceId[priceId] : totalShortPerPriceId[priceId]
      ).add(position)
    ).divDown(
        isBuy
          ? impactRefDepthLongPerPriceId[priceId]
          : impactRefDepthShortPerPriceId[priceId]
      );
    return uint256(price).mulDown(impact).divDown(uint256(100e18)).toUint128();
  }

  // abstract functions

  function openMarketOrder(
    Trade memory trade
  ) external virtual returns (bytes32);

  function closeMarketOrder(
    bytes32 orderHash,
    uint64 closePercent
  ) external virtual;

  function updateOpenOrder(
    bytes32 orderHash,
    Trade memory trade
  ) external virtual;
}