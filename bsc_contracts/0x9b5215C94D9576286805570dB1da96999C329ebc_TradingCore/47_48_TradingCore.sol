// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./interfaces/IRegistryCore.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ITradingCore.sol";
import "./interfaces/AbstractOracleAggregator.sol";
import "./interfaces/IDistributable.sol";
import "./libs/TradingCoreLib.sol";
import "./libs/math/FixedPoint.sol";
import "./libs/ERC20Fixed.sol";
import "./libs/Errors.sol";
import "./utils/Allowlistable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract TradingCore is
  ITradingCore,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  Allowlistable
{
  using FixedPoint for uint256;
  using FixedPoint for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ERC20Fixed for ERC20;

  bytes32 public constant APPROVED_ROLE = keccak256("APPROVED_ROLE");

  IRegistryCore public registry;
  IPool public liquidityPool;
  IPool public marginPool;
  IDistributable public revenuePool;
  ERC20 public baseToken;

  AbstractOracleAggregator public oracleAggregator; //settable

  event SetOracleAggregatorEvent(AbstractOracleAggregator oracleAggregator);

  function initialize(
    address _owner,
    AbstractOracleAggregator _oracleAggregator,
    ERC20 _baseToken,
    IRegistryCore _registry,
    IPool _liquidityPool,
    IPool _marginPool,
    IDistributable _revenuePool
  ) external initializer {
    __AccessControl_init();
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();
    __Allowlistable_init();

    _transferOwnership(_owner);
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    baseToken = _baseToken;
    liquidityPool = _liquidityPool;
    registry = _registry;
    marginPool = _marginPool;
    oracleAggregator = _oracleAggregator;
    revenuePool = _revenuePool;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // modifiers

  modifier onlyLiquidator() {
    _require(registry.isLiquidator(msg.sender), Errors.LIQUIDATOR_ONLY);
    _;
  }

  // governance functions

  function onAllowlist() external onlyOwner {
    _onAllowlist();
  }

  function offAllowlist() external onlyOwner {
    _offAllowlist();
  }

  function addAllowlist(address[] memory _allowed) external onlyOwner {
    _addAllowlist(_allowed);
  }

  function removeAllowlist(address[] memory _removed) external onlyOwner {
    _removeAllowlist(_removed);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setOracleAggregator(
    AbstractOracleAggregator _oracleAggregator
  ) external onlyOwner {
    oracleAggregator = _oracleAggregator;
    emit SetOracleAggregatorEvent(oracleAggregator);
  }

  // priviledged functions

  function openMarketOrder(
    OpenTradeInput calldata openData,
    uint128 openPrice
  ) external whenNotPaused nonReentrant onlyRole(APPROVED_ROLE) {
    _openMarketOrder(openData, openPrice);
  }

  function liquidateMarketOrder(
    CloseTradeInput calldata closeData,
    bytes[] calldata priceData
  ) external whenNotPaused nonReentrant onlyLiquidator returns (uint128) {
    IRegistry.Trade memory trade = registry.openTradeByOrderHash(
      closeData.orderHash
    );

    IOracleProvider.PricePackage memory pricePackage = oracleAggregator
      .parsePriceFeed(trade.user, trade.priceId, priceData);
    _require(
      trade.executionTime < pricePackage.publishTime,
      Errors.INVALID_TIMESTAMP
    );

    return
      _closeMarketOrder(
        closeData,
        trade.isBuy ? pricePackage.bid : pricePackage.ask,
        true
      );
  }

  // external functions

  function openMarketOrder(
    OpenTradeInput calldata openData,
    bytes[] calldata priceData
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    _require(
      openData.user == msg.sender || hasRole(APPROVED_ROLE, msg.sender),
      Errors.USER_SENDER_MISMATCH
    );

    uint256 updateFee = oracleAggregator.getUpdateFee(priceData.length);
    IOracleProvider.PricePackage memory pricePackage = oracleAggregator
      .updateLatestPrice{value: updateFee}(
      openData.user,
      openData.priceId,
      priceData,
      updateFee
    );

    _openMarketOrder(
      openData,
      openData.isBuy ? pricePackage.ask : pricePackage.bid
    );
  }

  function closeMarketOrder(
    CloseTradeInput calldata closeData,
    bytes[] calldata priceData
  )
    external
    payable
    whenNotPaused
    nonReentrant
    onlyAllowlisted
    returns (uint128 settled)
  {
    IRegistry.Trade memory trade = registry.openTradeByOrderHash(
      closeData.orderHash
    );

    _require(
      trade.user == msg.sender || hasRole(APPROVED_ROLE, msg.sender),
      Errors.USER_SENDER_MISMATCH
    );

    uint256 updateFee = oracleAggregator.getUpdateFee(priceData.length);
    IOracleProvider.PricePackage memory pricePackage = oracleAggregator
      .updateLatestPrice{value: updateFee}(
      trade.user,
      trade.priceId,
      priceData,
      updateFee
    );

    settled = _closeMarketOrder(
      closeData,
      trade.isBuy ? pricePackage.bid : pricePackage.ask,
      false
    );
  }

  function addMargin(
    bytes32 orderHash,
    bytes[] calldata priceData,
    uint128 margin
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    IRegistry.Trade memory t = registry.openTradeByOrderHash(orderHash);

    _require(
      t.user == msg.sender || hasRole(APPROVED_ROLE, msg.sender),
      Errors.USER_SENDER_MISMATCH
    );

    uint256 updateFee = oracleAggregator.getUpdateFee(priceData.length);
    IOracleProvider.PricePackage memory pricePackage = oracleAggregator
      .updateLatestPrice{value: updateFee}(
      t.user,
      t.priceId,
      priceData,
      updateFee
    );

    IRegistry.Trade memory trade = registry.updateTrade(
      orderHash,
      t.isBuy ? pricePackage.bid : pricePackage.ask,
      margin,
      true
    );

    registry.updateOpenOrder(orderHash, trade);
    baseToken.transferFromFixed(msg.sender, address(marginPool), margin);

    // audit(S): UNW-1
    emit UpdateOpenOrderEvent(
      msg.sender,
      orderHash,
      trade,
      OnUpdateTrade(true, margin),
      registry.onOrderUpdate(orderHash)
    );
  }

  function removeMargin(
    bytes32 orderHash,
    bytes[] calldata priceData,
    uint128 margin
  ) external payable whenNotPaused nonReentrant onlyAllowlisted {
    IRegistry.Trade memory t = registry.openTradeByOrderHash(orderHash);

    _require(
      t.user == msg.sender || hasRole(APPROVED_ROLE, msg.sender),
      Errors.USER_SENDER_MISMATCH
    );

    uint256 updateFee = oracleAggregator.getUpdateFee(priceData.length);
    IOracleProvider.PricePackage memory pricePackage = oracleAggregator
      .updateLatestPrice{value: updateFee}(
      t.user,
      t.priceId,
      priceData,
      updateFee
    );

    IRegistry.Trade memory trade = registry.updateTrade(
      orderHash,
      t.isBuy ? pricePackage.bid : pricePackage.ask,
      margin,
      false
    );

    registry.updateOpenOrder(orderHash, trade);
    marginPool.transferBase(msg.sender, margin);

    // audit(S): UNW-1
    emit UpdateOpenOrderEvent(
      msg.sender,
      orderHash,
      trade,
      OnUpdateTrade(false, margin),
      registry.onOrderUpdate(orderHash)
    );
  }

  function updateStop(
    bytes32 orderHash,
    bytes[] calldata priceData,
    uint128 profitTarget,
    uint128 stopLoss
  ) external payable whenNotPaused onlyAllowlisted {
    IRegistry.Trade memory t = registry.openTradeByOrderHash(orderHash);
    _require(t.user == msg.sender, Errors.USER_SENDER_MISMATCH);
    IOracleProvider.PricePackage memory pricePackage;
    {
      uint256 updateFee = oracleAggregator.getUpdateFee(priceData.length);
      pricePackage = oracleAggregator.updateLatestPrice{value: updateFee}(
        t.user,
        t.priceId,
        priceData,
        updateFee
      );
    }
    IRegistry.Trade memory trade = registry.updateStop(
      orderHash,
      t.isBuy ? pricePackage.bid : pricePackage.ask,
      profitTarget,
      stopLoss
    );
    registry.updateOpenOrder(orderHash, trade);

    // audit(S): UNW-1
    emit UpdateOpenOrderEvent(
      msg.sender,
      orderHash,
      trade,
      OnUpdateTrade(true, 0),
      registry.onOrderUpdate(orderHash)
    );
  }

  // internal functions

  function _openMarketOrder(
    OpenTradeInput memory openData,
    uint128 openPrice
  ) internal {
    (IRegistry.Trade memory trade, IFee.Fee memory _fee) = TradingCoreLib
      .canOpenMarketOrder(this, registry, openData, openPrice);

    bytes32 orderHash = registry.openMarketOrder(trade);

    uint256 netFee = uint256(_fee.fee).sub(_fee.referralFee);
    uint256 netFeeRebate = netFee.mulDown(registry.feeFactor());

    baseToken.transferFromFixed(msg.sender, address(marginPool), trade.margin);
    baseToken.transferFromFixed(msg.sender, owner(), netFee.sub(netFeeRebate));
    baseToken.transferFromFixed(msg.sender, address(this), netFeeRebate);

    baseToken.approveFixed(address(revenuePool), netFeeRebate);
    revenuePool.transferIn(netFeeRebate);

    if (_fee.referrer != address(0)) {
      baseToken.transferFromFixed(msg.sender, _fee.referrer, _fee.referralFee);
    }

    emit OpenMarketOrderEvent(
      openData.user,
      orderHash,
      trade,
      _fee,
      registry.onOrderUpdate(orderHash)
    );
  }

  function _closeMarketOrder(
    CloseTradeInput memory closeData,
    uint256 closePrice,
    bool isLiquidator
  ) internal returns (uint128) {
    _require(
      isLiquidator
        ? closeData.closePercent == 1e18
        : (closeData.closePercent > 0 && closeData.closePercent <= 1e18),
      Errors.INVALID_CLOSE_PERCENT
    );

    IRegistry.Trade memory trade = registry.openTradeByOrderHash(
      closeData.orderHash
    );

    OnCloseTrade memory onCloseTrade = TradingCoreLib.closeTrade(
      registry,
      closeData.orderHash,
      trade,
      closeData.closePercent,
      closePrice.toUint128()
    );

    if (isLiquidator && !(onCloseTrade.isLiquidated || onCloseTrade.isStop)) {
      _revert(Errors.CANNOT_LIQUIDATE);
    }

    _require(
      trade.isBuy
        ? closeData.limitPrice <= onCloseTrade.closeNet
        : closeData.limitPrice >= onCloseTrade.closeNet,
      Errors.SLIPPAGE_EXCEEDS_LIMIT
    );

    registry.closeMarketOrder(
      closeData.orderHash,
      uint256(closeData.closePercent).toUint64()
    );

    AfterCloseTrade memory afterCloseTrade;
    (onCloseTrade, afterCloseTrade) = TradingCoreLib.onAfterCloseTrade(
      registry,
      trade,
      closeData.closePercent,
      isLiquidator,
      onCloseTrade
    );

    marginPool.transferBase(
      address(liquidityPool),
      uint256(trade.margin).mulDown(closeData.closePercent)
    );

    {
      uint256 netFee = uint256(afterCloseTrade.fees.fee).sub(
        afterCloseTrade.fees.referralFee
      );
      uint256 netFeeRebate = netFee.mulDown(registry.feeFactor());
      liquidityPool.transferBase(owner(), netFee.sub(netFeeRebate));
      liquidityPool.transferBase(address(this), netFeeRebate);
      baseToken.approveFixed(address(revenuePool), netFeeRebate);
      revenuePool.transferIn(netFeeRebate);

      if (afterCloseTrade.fees.referrer != address(0)) {
        liquidityPool.transferBase(
          afterCloseTrade.fees.referrer,
          afterCloseTrade.fees.referralFee
        );
      }
    }

    if (isLiquidator) {
      if (onCloseTrade.isLiquidated || onCloseTrade.isStop) {
        liquidityPool.transferBase(msg.sender, afterCloseTrade.liquidationFee);
        liquidityPool.transferBase(trade.user, afterCloseTrade.settled);
      } else {
        _revert(Errors.CANNOT_LIQUIDATE);
      }
    } else {
      liquidityPool.transferBase(msg.sender, afterCloseTrade.settled);
    }

    emit CloseMarketOrderEvent(
      tx.origin,
      closeData.orderHash,
      closeData.closePercent,
      trade,
      onCloseTrade,
      afterCloseTrade,
      closeData.closePercent < 1e18
        ? registry.onOrderUpdate(closeData.orderHash)
        : IRegistryCore.OnOrderUpdate(
          IRegistryCore.SignedBalance(0, 0),
          0,
          IRegistryCore.AccruedFee(0, 0, 0)
        )
    );

    return afterCloseTrade.settled;
  }
}