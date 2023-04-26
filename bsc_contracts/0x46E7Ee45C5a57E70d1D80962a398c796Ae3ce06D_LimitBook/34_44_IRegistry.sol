// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

interface IRegistry {
  struct Trade {
    address user;
    bool isBuy;
    uint32 executionBlock;
    uint32 executionTime;
    bytes32 priceId;
    uint128 margin;
    uint128 leverage;
    uint128 openPrice;
    uint128 slippage;
    uint128 liquidationPrice;
    uint128 profitTarget;
    uint128 stopLoss;
    uint128 maxPercentagePnL;
    uint128 salt;
  }

  function openMarketOrder(Trade memory trade) external returns (bytes32);

  function closeMarketOrder(bytes32 orderHash, uint64 closePercent) external;

  function updateOpenOrder(bytes32 orderHash, Trade memory trade) external;

  function openTradeByOrderHash(
    bytes32 orderHash
  ) external view returns (Trade memory);

  function approvedPriceId(bytes32 priceId) external view returns (bool);

  function getSlippage(
    bytes32 priceId,
    bool isBuy,
    uint128 price,
    uint128 position
  ) external view returns (uint128);

  function liquidationThresholdPerPriceId(
    bytes32 priceId
  ) external view returns (uint64);

  function isLiquidator(address user) external view returns (bool);

  function maxPercentagePnLFactor() external view returns (uint128);

  function maxPercentagePnLCap() external view returns (uint128);

  function maxPercentagePnLFloor() external view returns (uint128);

  function maxLeveragePerPriceId(
    bytes32 priceId
  ) external view returns (uint128);

  function maxOpenTradesPerPriceId() external view returns (uint16);

  function maxOpenTradesPerUser() external view returns (uint16);

  function maxMarginPerUser() external view returns (uint128);

  function minPositionPerTrade() external view returns (uint128);

  function liquidationPenalty() external view returns (uint64);

  function stopFee() external view returns (uint128);

  function feeFactor() external view returns (uint64);

  function totalMarginPerUser(address user) external view returns (uint128);

  function minCollateral() external view returns (uint128);

  function openTradesPerPriceIdCount(
    address user,
    bytes32 priceId
  ) external view returns (uint128);

  function openTradesPerUserCount(address user) external view returns (uint128);

  function totalLongPerPriceId(bytes32 priceId) external view returns (uint128);

  function totalShortPerPriceId(
    bytes32 priceId
  ) external view returns (uint128);
}