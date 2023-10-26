//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMoneyMarket.sol";

interface IUnderlyingPositionFactoryEvents {

    event UnderlyingPositionCreated(address indexed account, PositionId indexed positionId);
    event MoneyMarketRegistered(MoneyMarketId indexed mm, IMoneyMarket indexed moneyMarket);

}

interface IUnderlyingPositionFactory is IUnderlyingPositionFactoryEvents {

    function registerMoneyMarket(IMoneyMarket imm) external;

    function createUnderlyingPosition(PositionId) external returns (IMoneyMarket);

    /// @return plain IMoneyMarket implementation without any position context
    function moneyMarket(MoneyMarketId) external view returns (IMoneyMarket);

    /// @return position context loaded IMoneyMarket
    function moneyMarket(PositionId) external view returns (IMoneyMarket);

}