// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IBook.sol";
import "./IFee.sol";
import "./IPool.sol";
import "./IRegistryCore.sol";
import "./AbstractOracleAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ITradingCore is IBook {
  struct OnCloseTrade {
    uint128 grossPnL;
    uint128 closeNet;
    uint128 slippage;
    int128 fundingFee;
    uint128 rolloverFee;
    bool isStop;
    bool isLiquidated;
  }

  struct OnUpdateTrade {
    bool isAdding;
    uint128 marginDelta;
  }

  struct AfterCloseTrade {
    uint128 oraclePrice;
    uint128 liquidationFee;
    uint128 settled;
    IFee.Fee fees;
  }

  event OpenMarketOrderEvent(
    address indexed user,
    bytes32 indexed orderHash,
    IRegistry.Trade trade,
    IFee.Fee fee,
    IRegistryCore.OnOrderUpdate onOrderUpdate
  );

  event UpdateOpenOrderEvent(
    address indexed user,
    bytes32 indexed orderHash,
    IRegistry.Trade trade,
    OnUpdateTrade onUpdateTrade,
    IRegistryCore.OnOrderUpdate onOrderUpdate
  );

  event CloseMarketOrderEvent(
    address indexed user,
    bytes32 indexed orderHash,
    uint256 closePercent,
    IRegistry.Trade trade,
    OnCloseTrade onCloseTrade,
    AfterCloseTrade afterCloseTrade,
    IRegistryCore.OnOrderUpdate onOrderUpdate
  );

  event FailedCloseMarketOrderEvent(
    bytes32 indexed orderHash,
    uint256 closePercent,
    uint128 limitPrice,
    bytes returnData
  );

  function openMarketOrder(
    OpenTradeInput calldata openData,
    bytes[] calldata priceData
  ) external payable;

  function openMarketOrder(
    OpenTradeInput calldata openData,
    uint128 openPrice
  ) external;

  function closeMarketOrder(
    CloseTradeInput calldata closeData,
    bytes[] calldata priceData
  ) external payable returns (uint128 settled);

  function addMargin(
    bytes32 orderHash,
    bytes[] calldata priceData,
    uint128 margin
  ) external payable;

  function removeMargin(
    bytes32 orderHash,
    bytes[] calldata priceData,
    uint128 margin
  ) external payable;

  function updateStop(
    bytes32 orderHash,
    bytes[] calldata priceData,
    uint128 profitTarget,
    uint128 stopLoss
  ) external payable;

  function baseToken() external view returns (ERC20);

  function liquidityPool() external view returns (IPool);

  function oracleAggregator() external view returns (AbstractOracleAggregator);
}