// SPDX-License-Identifier: BUSL-1.1

import "./interfaces/IRegistryCore.sol";
import "./interfaces/AbstractRegistry.sol";

pragma solidity ^0.8.17;

contract RegistryCore is AbstractRegistry, IRegistryCore {
  using SafeCast for uint256;
  using SafeCast for int256;
  using FixedPoint for uint256;
  using FixedPoint for int256;

  IFee internal fees;

  mapping(bytes32 => uint128) public fundingFeePerPriceId;
  mapping(bytes32 => uint128) public rolloverFeePerPriceId;

  mapping(bytes32 => SignedBalance) internal _longFundingFeePerPriceId;
  mapping(bytes32 => SignedBalance) internal _shortFundingFeePerPriceId;

  mapping(bytes32 => int128) internal _fundingFeeBaseByOrderHash;
  mapping(bytes32 => AccruedFee) internal _accruedFeeByOrderHash;

  event SetFeesEvent(address fees);
  event SetFundingFeeEvent(bytes32 priceId, uint256 fundingFee);
  event SetRolloverFeeEvent(bytes32 priceId, uint256 rolloverFee);

  function initialize(
    address _owner,
    uint16 _maxOpenTradesPerPriceId,
    uint16 _maxOpenTradesPerUser,
    uint128 _maxMarginPerUser,
    uint128 _minPositionPerTrade,
    uint64 _liquidationPenalty,
    uint128 _maxPercentagePnLFactor,
    uint128 _stopFee,
    IFee _fees
  ) external initializer {
    __AbstractRegistry_init(
      _owner,
      _maxOpenTradesPerPriceId,
      _maxOpenTradesPerUser,
      _maxMarginPerUser,
      _minPositionPerTrade,
      _liquidationPenalty,
      _maxPercentagePnLFactor,
      _stopFee,
      0
    );
    fees = _fees;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  // external functions

  function getFee() external view override returns (uint256) {
    return fees.getFee(msg.sender).fee;
  }

  function getFee(
    address _user
  ) external view override returns (IFee.Fee memory) {
    return fees.getFee(_user);
  }

  function getAccumulatedFee(
    bytes32 orderHash,
    uint64 closePercent
  ) external view override returns (int128 fundingFee, uint128 rolloverFee) {
    _require(closePercent <= 1e18, Errors.INVALID_CLOSE_PERCENT);
    Trade memory trade = _openTradeByOrderHash(orderHash);
    (, AccruedFee memory accruedFee) = _getAccumulatedFee(
      orderHash,
      trade.priceId,
      trade.isBuy,
      trade.leverage,
      trade.margin
    );
    fundingFee = int256(accruedFee.fundingFee).mulDown(closePercent).toInt128();
    rolloverFee = uint256(accruedFee.rolloverFee)
      .mulDown(closePercent)
      .toUint128();
  }

  function longFundingFeePerPriceId(
    bytes32 priceId
  ) external view returns (SignedBalance memory) {
    return _longFundingFeePerPriceId[priceId];
  }

  function shortFundingFeePerPriceId(
    bytes32 priceId
  ) external view returns (SignedBalance memory) {
    return _shortFundingFeePerPriceId[priceId];
  }

  function fundingFeeBaseByOrderHash(
    bytes32 orderHash
  ) external view returns (int256) {
    return _fundingFeeBaseByOrderHash[orderHash];
  }

  function accruedFeeByOrderHash(
    bytes32 orderHash
  ) external view returns (AccruedFee memory) {
    return _accruedFeeByOrderHash[orderHash];
  }

  function onOrderUpdate(
    bytes32 orderHash
  ) external view override returns (OnOrderUpdate memory _onOrderUpdate) {
    Trade memory trade = _openTradeByOrderHash(orderHash);
    _onOrderUpdate.feeBalance = trade.isBuy
      ? _longFundingFeePerPriceId[trade.priceId]
      : _shortFundingFeePerPriceId[trade.priceId];
    _onOrderUpdate.feeBase = _fundingFeeBaseByOrderHash[orderHash];
    _onOrderUpdate.accruedFee = _accruedFeeByOrderHash[orderHash];
  }

  function updateTrade(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 margin,
    bool isAdd
  ) external view override returns (Trade memory trade) {
    return _updateTrade(orderHash, closePrice, margin, isAdd);
  }

  function updateStop(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 profitTarget,
    uint128 stopLoss
  ) external view returns (Trade memory trade) {
    return _updateStop(orderHash, closePrice, profitTarget, stopLoss);
  }

  // governance functions

  function setFees(IFee _fees) external onlyOwner {
    fees = _fees;
    emit SetFeesEvent(address(fees));
  }

  function setFundingFeePerPriceId(
    bytes32 priceId,
    uint128 _fundingFee
  ) external onlyOwner {
    fundingFeePerPriceId[priceId] = _fundingFee;
    emit SetFundingFeeEvent(priceId, _fundingFee);
  }

  function setRolloverFeePerPriceId(
    bytes32 priceId,
    uint128 _rolloverFee
  ) external onlyOwner {
    rolloverFeePerPriceId[priceId] = _rolloverFee;
    emit SetRolloverFeeEvent(priceId, _rolloverFee);
  }

  // privilidged functions

  function openMarketOrder(
    Trade memory trade
  )
    external
    override(IRegistry, AbstractRegistry)
    onlyRole(APPROVED_ROLE)
    onlyApprovedPriceId(trade.priceId)
    returns (bytes32)
  {
    salt++;
    trade.salt = salt;
    bytes32 orderHash = keccak256(abi.encode(trade));
    openTradesPerPriceIdCount[trade.user][trade.priceId]++;
    openTradesPerUserCount[trade.user]++;
    totalMarginPerUser[trade.user] = uint256(totalMarginPerUser[trade.user])
      .add(trade.margin)
      .toUint128();

    _accruedFeeByOrderHash[orderHash].lastUpdate = trade.executionBlock;

    _updateFundingFeeBalance(
      orderHash,
      trade.priceId,
      trade.isBuy,
      0,
      0,
      trade.leverage,
      trade.margin
    );

    // audit(B): L05
    minCollateral += uint256(trade.margin)
      .mulUp(trade.maxPercentagePnL)
      .toUint128();

    __openTradeByOrderHash[orderHash] = trade;

    return orderHash;
  }

  function closeMarketOrder(
    bytes32 orderHash,
    uint64 closePercent
  ) external override(AbstractRegistry, IRegistry) onlyRole(APPROVED_ROLE) {
    Trade memory t = _openTradeByOrderHash(orderHash);
    uint256 closeMargin = uint256(t.margin).mulDown(closePercent);

    totalMarginPerUser[t.user] = uint256(totalMarginPerUser[t.user])
      .sub(closeMargin)
      .toUint128();
    minCollateral -= uint256(closeMargin)
      .mulDown(uint256(t.maxPercentagePnL))
      .toUint128();

    _updateFundingFeeBalance(
      orderHash,
      t.priceId,
      t.isBuy,
      t.leverage,
      t.margin,
      t.leverage,
      uint256(t.margin).sub(closeMargin).toUint128()
    );

    if (closePercent == 1e18) {
      openTradesPerPriceIdCount[t.user][t.priceId]--;
      openTradesPerUserCount[t.user]--;
      delete __openTradeByOrderHash[orderHash];
      delete _fundingFeeBaseByOrderHash[orderHash];
      delete _accruedFeeByOrderHash[orderHash];
    } else {
      t.margin -= closeMargin.toUint128();
      __openTradeByOrderHash[orderHash] = t;
    }
  }

  function updateOpenOrder(
    bytes32 orderHash,
    Trade memory trade
  ) external override(AbstractRegistry, IRegistry) onlyRole(APPROVED_ROLE) {
    Trade memory t = __openTradeByOrderHash[orderHash];

    _require(t.user == trade.user, Errors.TRADER_OWNER_MISMATCH);
    _require(t.priceId == trade.priceId, Errors.PRICE_ID_MISMATCH);
    _require(t.isBuy == trade.isBuy, Errors.TRADE_DIRECTION_MISMATCH);
    // audit(M): lack of check of salt
    _require(t.salt == trade.salt, Errors.TRADE_SALT_MISMATCH);

    _updateFundingFeeBalance(
      orderHash,
      t.priceId,
      t.isBuy,
      t.leverage,
      t.margin,
      trade.leverage,
      trade.margin
    );

    totalMarginPerUser[trade.user] = uint256(totalMarginPerUser[trade.user])
      .sub(t.margin)
      .add(trade.margin)
      .toUint128();
    minCollateral -= uint256(t.margin).mulDown(t.maxPercentagePnL).toUint128();
    // audit(B): M02, L05
    minCollateral += uint256(trade.margin)
      .mulUp(trade.maxPercentagePnL)
      .toUint128();

    __openTradeByOrderHash[orderHash] = trade;
  }

  // internal functions

  function _updateFundingFeeBalance(
    bytes32 orderHash,
    bytes32 priceId,
    bool isBuy,
    uint128 oldLeverage,
    uint128 oldMargin,
    uint128 newLeverage,
    uint128 newMargin
  ) internal {
    (
      SignedBalance memory _fundingFee,
      AccruedFee memory _accruedFee
    ) = _getAccumulatedFee(orderHash, priceId, isBuy, oldLeverage, oldMargin);

    uint256 _totalPosition = isBuy
      ? totalLongPerPriceId[priceId]
      : totalShortPerPriceId[priceId];

    SignedBalance memory _fundingFeeT = isBuy
      ? _getLatestFundingFeeBalance(
        _shortFundingFeePerPriceId[priceId],
        totalShortPerPriceId[priceId],
        _totalPosition,
        fundingFeePerPriceId[priceId]
      )
      : _getLatestFundingFeeBalance(
        _longFundingFeePerPriceId[priceId],
        totalLongPerPriceId[priceId],
        _totalPosition,
        fundingFeePerPriceId[priceId]
      );

    // simulate out
    int256 balanceOut = int256(_accruedFee.fundingFee).add(
      _fundingFeeBaseByOrderHash[orderHash]
    );

    _totalPosition = _totalPosition.sub(
      uint256(oldLeverage).mulDown(oldMargin)
    );

    _fundingFee.balance = int256(_fundingFee.balance)
      .sub(balanceOut)
      .toInt128();

    if (uint256(oldLeverage).mulDown(oldMargin) > 0) {
      uint256 ratio = uint256(newLeverage)
        .mulDown(newMargin)
        .divDown(oldLeverage)
        .divDown(oldMargin);
      _accruedFee.fundingFee = int256(_accruedFee.fundingFee)
        .mulDown(ratio)
        .toInt128();
      _accruedFee.rolloverFee = uint256(_accruedFee.rolloverFee)
        .mulDown(ratio)
        .toUint128();
    }

    // simulate in
    int256 balanceIn = _fundingFee.balance;
    if (_totalPosition > 0)
      balanceIn = balanceIn.mulDown(newLeverage).mulDown(newMargin).divDown(
        _totalPosition
      );
    balanceIn = balanceIn.add(_accruedFee.fundingFee);

    _fundingFee.balance = int256(_fundingFee.balance).add(balanceIn).toInt128();
    _totalPosition = _totalPosition.add(
      uint256(newLeverage).mulDown(newMargin)
    );

    _fundingFeeBaseByOrderHash[orderHash] = balanceIn.toInt128();
    _accruedFeeByOrderHash[orderHash] = _accruedFee;

    if (isBuy) {
      _longFundingFeePerPriceId[priceId] = _fundingFee;
      _shortFundingFeePerPriceId[priceId] = _fundingFeeT;
      totalLongPerPriceId[priceId] = _totalPosition.toUint128();
    } else {
      _shortFundingFeePerPriceId[priceId] = _fundingFee;
      _longFundingFeePerPriceId[priceId] = _fundingFeeT;
      totalShortPerPriceId[priceId] = _totalPosition.toUint128();
    }
  }

  function _getLatestFundingFeeBalance(
    SignedBalance memory _fundingFee,
    uint256 totalPositionM,
    uint256 totalPositionT,
    uint128 fundingFeePerBlock
  ) internal view returns (SignedBalance memory fundingFee) {
    fundingFee = _fundingFee;

    if (fundingFee.lastUpdate > 0)
      fundingFee.balance = int256(fundingFee.balance)
        .add(
          uint256(fundingFeePerBlock).mulDown(
            int256(totalPositionM).sub(totalPositionT)
          ) * (block.number.sub(uint256(fundingFee.lastUpdate))).toInt256()
        )
        .toInt128();
    fundingFee.lastUpdate = block.number.toUint32();
  }

  function _getAccumulatedFee(
    bytes32 orderHash,
    bytes32 priceId,
    bool isBuy,
    uint128 leverage,
    uint128 margin
  )
    internal
    view
    returns (SignedBalance memory fundingFee, AccruedFee memory accruedFee)
  {
    uint256 _totalPosition = isBuy
      ? totalLongPerPriceId[priceId]
      : totalShortPerPriceId[priceId];
    fundingFee = isBuy
      ? _getLatestFundingFeeBalance(
        _longFundingFeePerPriceId[priceId],
        _totalPosition,
        totalShortPerPriceId[priceId],
        fundingFeePerPriceId[priceId]
      )
      : _getLatestFundingFeeBalance(
        _shortFundingFeePerPriceId[priceId],
        _totalPosition,
        totalLongPerPriceId[priceId],
        fundingFeePerPriceId[priceId]
      );

    int256 accruedFundingFee = fundingFee.balance;
    if (_totalPosition > 0)
      accruedFundingFee = accruedFundingFee
        .mulDown(leverage)
        .mulDown(margin)
        .divDown(_totalPosition);
    accruedFundingFee = accruedFundingFee.sub(
      _fundingFeeBaseByOrderHash[orderHash]
    );

    accruedFee = _accruedFeeByOrderHash[orderHash];
    accruedFee.fundingFee = int256(accruedFee.fundingFee)
      .add(accruedFundingFee)
      .toInt128();

    accruedFee.rolloverFee = uint256(accruedFee.rolloverFee)
      .add(
        uint256(rolloverFeePerPriceId[priceId]).mulDown(margin) *
          (block.number.sub(uint256(accruedFee.lastUpdate)))
      )
      .toUint128();
    accruedFee.lastUpdate = block.number.toUint32();
  }

  function _updateTrade(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 margin,
    bool isAdd
  ) internal view returns (Trade memory trade) {
    trade = _openTradeByOrderHash(orderHash);

    uint256 position = uint256(trade.leverage).mulDown(trade.margin);
    (, AccruedFee memory accruedFee) = _getAccumulatedFee(
      orderHash,
      trade.priceId,
      trade.isBuy,
      trade.leverage,
      trade.margin
    );

    {
      if (isAdd) {
        uint256 maxMargin = position.divDown(
          minLeveragePerPriceId[trade.priceId]
        );
        _require(
          uint256(trade.margin).add(margin) <= maxMargin,
          Errors.INVALID_MARGIN
        );

        trade.margin = uint256(trade.margin).add(margin).toUint128();
      } else {
        uint256 minMargin = position.divDown(
          maxLeveragePerPriceId[trade.priceId]
        );
        _require(trade.margin > margin, Errors.INVALID_MARGIN);
        _require(
          uint256(trade.margin).sub(margin) >= minMargin,
          Errors.LEVERAGE_TOO_HIGH
        );

        trade.margin = uint256(trade.margin).sub(margin).toUint128();
      }
    }

    trade.leverage = position.divDown(trade.margin).toUint128();

    {
      int256 accumulatedFee = int256(accruedFee.fundingFee).add(
        uint256(accruedFee.rolloverFee)
      );

      if (trade.isBuy) {
        uint256 executionPrice = uint256(trade.openPrice).add(trade.slippage);
        int256 accumulatedFeePerPrice = executionPrice
          .mulDown(accumulatedFee)
          .divDown(position);
        trade.liquidationPrice = executionPrice
          .mulDown(
            uint256(trade.leverage)
              .sub(uint256(liquidationThresholdPerPriceId[trade.priceId]))
              .divDown(uint256(trade.leverage))
          )
          .toUint128();
        _require(
          closePrice >
            int256(uint256(trade.liquidationPrice).add(accumulatedFeePerPrice))
              .toUint256(),
          Errors.INVALID_MARGIN
        );
      } else {
        uint256 executionPrice = uint256(trade.openPrice).sub(trade.slippage);
        int256 accumulatedFeePerPrice = executionPrice
          .mulDown(accumulatedFee)
          .divDown(position);
        trade.liquidationPrice = executionPrice
          .mulDown(
            uint256(trade.leverage)
              .add(uint256(liquidationThresholdPerPriceId[trade.priceId]))
              .divDown(uint256(trade.leverage))
          )
          .toUint128();
        _require(
          closePrice <
            int256(uint256(trade.liquidationPrice).sub(accumulatedFeePerPrice))
              .toUint256(),
          Errors.INVALID_MARGIN
        );
      }
    }

    trade.maxPercentagePnL = position
      .divDown(uint256(maxPercentagePnLFactor))
      .divDown(uint256(trade.margin))
      .min(uint256(maxPercentagePnLCap))
      .max(uint256(maxPercentagePnLFloor))
      .toUint128();
  }

  function _updateStop(
    bytes32 orderHash,
    uint128 closePrice,
    uint128 profitTarget,
    uint128 stopLoss
  ) internal view returns (Trade memory trade) {
    trade = _openTradeByOrderHash(orderHash);

    uint256 closePosition = uint256(trade.leverage).mulDown(trade.margin);

    (, AccruedFee memory accruedFee) = _getAccumulatedFee(
      orderHash,
      trade.priceId,
      trade.isBuy,
      trade.leverage,
      trade.margin
    );

    int256 accumulatedFee = int256(accruedFee.fundingFee).add(
      accruedFee.rolloverFee
    );

    uint256 openNet = trade.isBuy
      ? uint256(trade.openPrice).add(trade.slippage)
      : uint256(trade.openPrice).sub(trade.slippage);

    uint256 closeNet = trade.isBuy
      ? int256(
        uint256(closePrice).sub(
          accumulatedFee.mulDown(openNet).divDown(closePosition)
        )
      ).toUint256()
      : int256(
        uint256(closePrice).add(
          accumulatedFee.mulDown(openNet).divDown(closePosition)
        )
      ).toUint256();

    _require(
      stopLoss == 0 ||
        (trade.isBuy ? stopLoss < closeNet : stopLoss > closeNet),
      Errors.INVALID_STOP_LOSS
    );
    _require(
      profitTarget == 0 ||
        (trade.isBuy ? profitTarget > closeNet : profitTarget < closeNet),
      Errors.INVALID_PROFIT_TARGET
    );

    trade.stopLoss = stopLoss;
    trade.profitTarget = profitTarget;
  }
}