// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ITrading.sol";
import "./IOrderAndTradeHistory.sol";

interface ITradingClose is ITrading {

    event CloseTradeSuccessful(address indexed user, bytes32 indexed tradeHash, IOrderAndTradeHistory.CloseInfo closeInfo);
    event ExecuteCloseSuccessful(address indexed user, bytes32 indexed tradeHash, ExecutionType executionType, IOrderAndTradeHistory.CloseInfo closeInfo);
    event CloseTradeReceived(address indexed user, bytes32 indexed tradeHash, address indexed token, uint256 amount);
    event CloseTradeAddLiquidity(address indexed token, uint256 amount);
    event ExecuteCloseRejected(address indexed user, bytes32 indexed tradeHash, ExecutionType executionType, uint64 execPrice, uint64 marketPrice);

    enum ExecutionType {TP, SL, LIQ}
    struct TpSlOrLiq {
        bytes32 tradeHash;
        uint64 price;
        ExecutionType executionType;
    }

    struct SettleToken {
        address token;
        uint256 amount;
        uint8 decimals;
    }

    function closeTradeCallback(bytes32 tradeHash, uint upperPrice, uint lowerPrice) external;

    function executeTpSlOrLiq(TpSlOrLiq[] memory) external;
}