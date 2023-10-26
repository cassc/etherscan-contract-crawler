// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IPoolFactory {
    function createPoolFromUni(address tradeToken, address poolToken, uint24 fee, bool reverse) external;

    function createPoolFromSushi(address tradeToken, address poolToken, bool reverse) external;

    function pools(address poolToken, address oraclePool, bool reverse) external view returns (address pool);

    event CreatePoolFromUni(
        address tradeToken,
        address poolToken,
        address uniPool,
        address pool,
        address debt,
        string tradePair,
        uint24 fee,
        bool reverse);

    event CreatePoolFromSushi(
        address tradeToken,
        address poolToken,
        address sushiPool,
        address pool,
        address debt,
        string tradePair,
        bool reverse);
}