// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./IRegistry.sol";
import "./IBook.sol";

interface ILimitBook is IBook {
  event OpenLimitOrderEvent(
    address indexed sender,
    bytes32 indexed orderHash,
    IRegistry.Trade trade
  );
  event UpdateOpenLimitOrderEvent(
    address indexed sender,
    bytes32 indexed orderHash,
    IRegistry.Trade trade
  );
  event ExecuteLimitOrderEvent(
    address indexed sender,
    bytes32 indexed orderHash,
    address trade_user,
    bytes32 trade_priceId
  );
  event CloseLimitOrderEvent(
    address indexed sender,
    bytes32 indexed orderHash,
    address trade_user,
    bytes32 trade_priceId
  );
  event PartialCloseLimitOrderEvent(
    address indexed sender,
    bytes32 indexed orderHash,
    IRegistry.Trade trade,
    uint64 closePercent
  );
  event FailedExecuteLimitOrderEvent(
    bytes32 indexed orderHash,
    bytes returnData
  );

  function openLimitOrder(OpenTradeInput calldata openData) external;

  function executeLimitOrder(
    bytes32 orderHash,
    bytes[] calldata priceData
  ) external;

  function closeLimitOrder(bytes32 orderHash, uint64 closePercent) external;
}