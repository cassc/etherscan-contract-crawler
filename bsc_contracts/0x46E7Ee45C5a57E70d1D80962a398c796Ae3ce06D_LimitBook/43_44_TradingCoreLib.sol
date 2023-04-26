// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/ITradingCore.sol";
import "../interfaces/IRegistryCore.sol";
import "./math/FixedPoint.sol";
import "./Errors.sol";
import "./ERC20Fixed.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TradingCoreLib is Initializable {
  using FixedPoint for uint256;
  using FixedPoint for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ERC20Fixed for ERC20;

  function initialize() public initializer {}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function canOpenMarketOrder(
    IRegistryCore registryCore,
    ITradingCore.OpenTradeInput memory openData,
    uint128 openPrice,
    uint256 liquidityBalance
  ) public view returns (IRegistry.Trade memory trade, IFee.Fee memory _fee) {
    _fee = registryCore.getOpenFee(openData.user);
    _fee.fee = uint256(openData.leverage)
      .mulDown(openData.margin)
      .mulDown(_fee.fee)
      .toUint128();
    _require(_fee.fee < openData.margin, Errors.FEE_TOO_HIGH);
    uint256 openPosition = uint256(openData.leverage).mulDown(openData.margin);
    openData.margin -= _fee.fee;

    _fee.referredFee = openPosition.mulDown(_fee.referredFee).toUint128();

    _fee.referralFee = openPosition.mulDown(_fee.referralFee).toUint128();

    uint256 slippage = registryCore.getSlippage(
      openData.priceId,
      openData.isBuy,
      openPrice,
      openPosition.toUint128()
    );
    trade = createTrade(
      registryCore,
      openData,
      openPrice,
      slippage.toUint128(),
      _fee.fee,
      liquidityBalance
    );
  }

  function createTrade(
    IRegistryCore registryCore,
    ITradingCore.OpenTradeInput memory openData,
    uint128 openPrice,
    uint128 slippage,
    uint128 fee,
    uint256 liquidityBalance
  ) public view returns (IRegistry.Trade memory trade) {
    uint256 executionPrice = openData.isBuy
      ? uint256(openPrice).add(slippage)
      : uint256(openPrice).sub(slippage);
    uint256 liquidationPrice = openData.isBuy
      ? executionPrice.mulDown(
        uint256(openData.leverage)
          .sub(registryCore.liquidationThresholdPerPriceId(openData.priceId))
          .divDown(openData.leverage)
      )
      : executionPrice.mulDown(
        uint256(openData.leverage)
          .add(registryCore.liquidationThresholdPerPriceId(openData.priceId))
          .divDown(openData.leverage)
      );
    uint256 maxPercentagePnL = uint256(openData.leverage)
      .divDown(registryCore.maxPercentagePnLFactor())
      .min(registryCore.maxPercentagePnLCap())
      .max(registryCore.maxPercentagePnLFloor());

    _require(openData.leverage > 0, Errors.NEGATIVE_LEVERAGE);
    _require(
      openData.leverage <= registryCore.maxLeveragePerPriceId(openData.priceId),
      Errors.LEVERAGE_TOO_HIGH
    );
    _require(
      registryCore.approvedPriceId(openData.priceId),
      Errors.APPROVED_PRICE_ID_ONLY
    );
    _require(
      registryCore.openTradesPerPriceIdCount(openData.user, openData.priceId) <
        registryCore.maxOpenTradesPerPriceId(),
      Errors.MAX_OPEN_TRADES_PER_PRICE_ID
    );
    _require(
      registryCore.openTradesPerUserCount(openData.user) <
        registryCore.maxOpenTradesPerUser(),
      Errors.MAX_OPEN_TRADES_PER_USER
    );
    _require(
      uint256(openData.margin).add(
        registryCore.totalMarginPerUser(openData.user)
      ) < registryCore.maxMarginPerUser(),
      Errors.MAX_MARGIN_PER_USER
    );
    _require(
      uint256(registryCore.minCollateral()).add(
        uint256(openData.margin).mulDown(maxPercentagePnL)
      ) <= liquidityBalance,
      Errors.MAX_LIQUIDITY_POOL
    );
    _require(
      openData.isBuy
        ? uint256(registryCore.totalLongPerPriceId(openData.priceId)).add(
          uint256(openData.leverage).mulDown(uint256(openData.margin))
        ) <= registryCore.maxTotalLongPerPriceId(openData.priceId)
        : uint256(registryCore.totalShortPerPriceId(openData.priceId)).add(
          uint256(openData.leverage).mulDown(uint256(openData.margin))
        ) <= registryCore.maxTotalShortPerPriceId(openData.priceId),
      Errors.MAX_TOTAL_POSITIONS
    );
    _require(
      uint256(openData.leverage).mulDown(uint256(openData.margin).add(fee)) >=
        registryCore.minPositionPerTrade(),
      Errors.POSITION_TOO_SMALL
    );
    _require(
      openData.isBuy
        ? liquidationPrice < openPrice
        : liquidationPrice > openPrice,
      Errors.SLIPPAGE_TOO_GREAT
    );
    _require(
      openData.stopLoss == 0 ||
        (
          openData.isBuy
            ? openData.stopLoss < executionPrice
            : openData.stopLoss > executionPrice
        ),
      Errors.INVALID_STOP_LOSS
    );
    _require(
      openData.profitTarget == 0 ||
        (
          openData.isBuy
            ? openData.profitTarget > executionPrice
            : openData.profitTarget < executionPrice
        ),
      Errors.INVALID_PROFIT_TARGET
    );
    _require(
      openData.isBuy
        ? openData.limitPrice >= executionPrice
        : openData.limitPrice <= executionPrice,
      Errors.SLIPPAGE_EXCEEDS_LIMIT
    );

    trade = IRegistry.Trade(
      openData.user, //whose trade
      openData.isBuy, //user input
      uint256(block.number).toUint32(),
      uint256(block.timestamp).toUint32(),
      openData.priceId,
      openData.margin,
      openData.leverage, //user input
      openPrice,
      slippage, //execution price,
      liquidationPrice.toUint128(),
      openData.profitTarget,
      openData.stopLoss,
      maxPercentagePnL.toUint128(),
      0 // unique number - set by Registry
    );
  }

  function closeTrade(
    IRegistryCore registryCore,
    bytes32 orderHash,
    uint64 closePercent,
    uint128 closePrice
  ) public view returns (ITradingCore.OnCloseTrade memory onCloseTrade) {
    IRegistry.Trade memory trade = registryCore.openTradeByOrderHash(orderHash);

    uint256 closeMargin = uint256(trade.margin).mulDown(closePercent);
    uint256 closePosition = uint256(trade.leverage).mulDown(closeMargin);

    (onCloseTrade.fundingFee, onCloseTrade.rolloverFee) = registryCore
      .getAccumulatedFee(
        orderHash,
        uint256(closeMargin).divDown(trade.margin).toUint64()
      );

    int256 accumulatedFee = int256(onCloseTrade.fundingFee).add(
      onCloseTrade.rolloverFee
    );

    uint256 openNet = trade.isBuy
      ? uint256(trade.openPrice).add(trade.slippage)
      : uint256(trade.openPrice).sub(trade.slippage);

    onCloseTrade.closeNet = trade.isBuy
      ? uint256(closePrice)
        .sub(accumulatedFee.mulDown(openNet).divDown(closePosition))
        .max(uint256(0))
        .toUint256()
        .toUint128()
      : uint256(closePrice)
        .add(accumulatedFee.mulDown(openNet).divDown(closePosition))
        .toUint256()
        .toUint128();

    // guaranteed execution (** before ** slippage)
    onCloseTrade.isStop = false;
    onCloseTrade.isLiquidated = false;
    if (
      trade.stopLoss > 0 &&
      ((trade.isBuy && onCloseTrade.closeNet <= trade.stopLoss) ||
        (!trade.isBuy && onCloseTrade.closeNet >= trade.stopLoss))
    ) {
      onCloseTrade.isStop = true;
      onCloseTrade.closeNet = trade.stopLoss;
    }
    if (
      trade.profitTarget > 0 &&
      ((trade.isBuy && onCloseTrade.closeNet >= trade.profitTarget) ||
        (!trade.isBuy && onCloseTrade.closeNet <= trade.profitTarget))
    ) {
      onCloseTrade.isStop = true;
      onCloseTrade.closeNet = trade.profitTarget;
    }
    if (
      !onCloseTrade.isStop &&
      ((trade.isBuy && onCloseTrade.closeNet <= trade.liquidationPrice) ||
        (!trade.isBuy && onCloseTrade.closeNet >= trade.liquidationPrice))
    ) {
      onCloseTrade.isLiquidated = true;
      onCloseTrade.closeNet = trade.liquidationPrice;
    }

    onCloseTrade.slippage = registryCore.getSlippage(
      trade.priceId,
      !trade.isBuy,
      onCloseTrade.closeNet,
      closePosition.toUint128()
    );
    onCloseTrade.closeNet = trade.isBuy
      ? uint256(onCloseTrade.closeNet).sub(onCloseTrade.slippage).toUint128()
      : uint256(onCloseTrade.closeNet).add(onCloseTrade.slippage).toUint128();

    uint256 absPositionPnL = (
      onCloseTrade.closeNet > openNet
        ? uint256(onCloseTrade.closeNet).sub(openNet)
        : openNet.sub(onCloseTrade.closeNet)
    ).mulDown(closePosition).divDown(openNet);

    bool isWinningMoney = (trade.isBuy && onCloseTrade.closeNet > openNet) ||
      (!trade.isBuy && openNet > onCloseTrade.closeNet);

    if (isWinningMoney) {
      onCloseTrade.grossPnL = uint256(closeMargin)
        .add(absPositionPnL)
        .toUint128();
    } else {
      onCloseTrade.grossPnL = closeMargin < absPositionPnL
        ? 0
        : uint256(closeMargin).sub(absPositionPnL).toUint128();
    }

    if (
      onCloseTrade.grossPnL >
      uint256(closeMargin).mulDown(trade.maxPercentagePnL)
    ) {
      onCloseTrade.isStop = true;
      onCloseTrade.grossPnL = uint256(closeMargin)
        .mulDown(trade.maxPercentagePnL)
        .toUint128();
    }
  }

  function onAfterCloseTrade(
    IRegistryCore registryCore,
    IRegistry.Trade memory trade,
    uint128 closePercent,
    bool isLiquidator,
    ITradingCore.OnCloseTrade memory _onCloseTrade
  )
    public
    view
    returns (
      ITradingCore.OnCloseTrade memory onCloseTrade,
      ITradingCore.AfterCloseTrade memory afterCloseTrade
    )
  {
    uint256 closePosition = uint256(trade.leverage)
      .mulDown(trade.margin)
      .mulDown(closePercent);
    onCloseTrade = _onCloseTrade;

    afterCloseTrade.fees = registryCore.getCloseFee(trade.user);
    afterCloseTrade.fees.fee = closePosition
      .mulDown(afterCloseTrade.fees.fee)
      .toUint128();

    uint256 pnlOverFee = 1e18;
    if (afterCloseTrade.fees.fee > 0) {
      pnlOverFee = uint256(onCloseTrade.grossPnL)
        .divDown(afterCloseTrade.fees.fee)
        .min(uint256(1e18));
    }

    afterCloseTrade.fees.fee = uint256(afterCloseTrade.fees.fee)
      .mulDown(pnlOverFee)
      .toUint128();

    onCloseTrade.grossPnL = uint256(onCloseTrade.grossPnL)
      .sub(afterCloseTrade.fees.fee)
      .toUint128();

    afterCloseTrade.fees.referredFee = closePosition
      .mulDown(afterCloseTrade.fees.referredFee)
      .mulDown(pnlOverFee)
      .toUint128();

    afterCloseTrade.fees.referralFee = closePosition
      .mulDown(afterCloseTrade.fees.referralFee)
      .mulDown(pnlOverFee)
      .toUint128();

    if (isLiquidator) {
      if (onCloseTrade.isLiquidated) {
        afterCloseTrade.liquidationFee = uint256(onCloseTrade.grossPnL)
          .mulDown(registryCore.liquidationPenalty())
          .toUint128();
        afterCloseTrade.settled = uint256(onCloseTrade.grossPnL)
          .sub(afterCloseTrade.liquidationFee)
          .toUint128();
      } else if (onCloseTrade.isStop) {
        afterCloseTrade.liquidationFee = uint256(onCloseTrade.grossPnL)
          .mulDown(registryCore.stopFee())
          .toUint128();
        afterCloseTrade.settled = uint256(onCloseTrade.grossPnL)
          .sub(afterCloseTrade.liquidationFee)
          .toUint128();
      }
    } else {
      afterCloseTrade.settled = onCloseTrade.grossPnL;
    }
  }
}