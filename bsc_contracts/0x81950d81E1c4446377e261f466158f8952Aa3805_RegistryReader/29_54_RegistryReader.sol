// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../RegistryCore.sol";
import "../OracleAggregator.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IRegistryCore.sol";
import "../interfaces/ITradingCore.sol";
import "../interfaces/IOracleProvider.sol";
import "../interfaces/AbstractOracleAggregator.sol";
import "../libs/math/FixedPoint.sol";
import "../libs/TradingCoreLib.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract RegistryReader {
  using FixedPoint for uint256;
  using SafeCast for uint256;

  struct MarketParameters {
    bytes32 priceId;
    bool approved;
    uint256 maxLeverage;
    uint256 minLeverage;
    uint256 liquidationThreshold;
    uint256 fundingFeeRate;
    uint256 rolloverFeeRate;
    uint256 impactRefDepthLong;
    uint256 impactRefDepthShort;
    IRegistryCore.SignedBalance longFundingFee;
    IRegistryCore.SignedBalance shortFundingFee;
    uint256 totalLong;
    uint256 totalShort;
    uint256 confMultiplier;
    uint256 staleThreshold;
  }

  function getMarketParameters(
    address registryAddress,
    address oracleAggregatorAddress,
    bytes32[] calldata priceIds
  ) external view returns (MarketParameters[] memory) {
    RegistryCore registry = RegistryCore(registryAddress);
    OracleAggregator oracle = OracleAggregator(oracleAggregatorAddress);
    MarketParameters[] memory values = new MarketParameters[](priceIds.length);
    for (uint32 i = 0; i < priceIds.length; ++i) {
      bytes32 priceId = priceIds[i];
      values[i] = MarketParameters(
        priceId,
        registry.approvedPriceId(priceId),
        registry.maxLeveragePerPriceId(priceId),
        registry.minLeveragePerPriceId(priceId),
        registry.liquidationThresholdPerPriceId(priceId),
        registry.fundingFeePerPriceId(priceId),
        registry.rolloverFeePerPriceId(priceId),
        registry.impactRefDepthLongPerPriceId(priceId),
        registry.impactRefDepthShortPerPriceId(priceId),
        registry.longFundingFeePerPriceId(priceId),
        registry.shortFundingFeePerPriceId(priceId),
        registry.totalLongPerPriceId(priceId),
        registry.totalShortPerPriceId(priceId),
        oracle.confMultiplierPerPriceId(priceId),
        oracle.staleThresholdPerPriceId(priceId)
      );
    }
    return values;
  }

  function getSlippage(
    address registryAddress,
    bytes32 priceId,
    bool isBuy,
    uint256 price,
    uint256 position
  ) external view returns (uint256) {
    return
      RegistryCore(registryAddress).getSlippage(
        priceId,
        isBuy,
        price.toUint128(),
        position.toUint128()
      );
  }

  function getAccumulatedFee(
    address registryAddress,
    bytes32 orderHash,
    uint256 closePercent
  ) external view returns (int256, uint256) {
    RegistryCore registry = RegistryCore(registryAddress);
    _require(
      closePercent > 0 && closePercent <= 1e18,
      Errors.INVALID_CLOSE_PERCENT
    );
    return registry.getAccumulatedFee(orderHash, closePercent.toUint64());
  }

  function canLiquidateMarketOrder(
    address tradingCoreAddress,
    address registryCoreAddress,
    IBook.CloseTradeInput calldata closeData,
    bytes[] calldata priceData
  ) external view returns (bool) {
    ITradingCore tradingCore = ITradingCore(tradingCoreAddress);
    IRegistryCore registry = IRegistryCore(registryCoreAddress);
    AbstractOracleAggregator oracleAggregator = tradingCore.oracleAggregator();
    IRegistry.Trade memory trade = registry.openTradeByOrderHash(
      closeData.orderHash
    );

    IOracleProvider.PricePackage memory pricePackage = oracleAggregator
      .parsePriceFeed(trade.user, trade.priceId, priceData);
    _require(
      trade.executionTime < pricePackage.publishTime,
      Errors.INVALID_TIMESTAMP
    );
    _require(closeData.closePercent == 1e18, Errors.INVALID_CLOSE_PERCENT);

    ITradingCore.OnCloseTrade memory onCloseTrade = TradingCoreLib.closeTrade(
      registry,
      closeData.orderHash,
      closeData.closePercent,
      trade.isBuy ? pricePackage.bid : pricePackage.ask
    );

    return onCloseTrade.isLiquidated || onCloseTrade.isStop;
  }

  function canOpenMarketOrder(
    address tradingCoreAddress,
    address registryCoreAddress,
    ITradingCore.OpenTradeInput memory openData,
    uint128 openPrice
  ) public view returns (IRegistry.Trade memory trade, IFee.Fee memory _fee) {
    ITradingCore tradingCore = ITradingCore(tradingCoreAddress);
    IRegistryCore registry = IRegistryCore(registryCoreAddress);
    return
      TradingCoreLib.canOpenMarketOrder(
        tradingCore,
        registry,
        openData,
        openPrice
      );
  }
}