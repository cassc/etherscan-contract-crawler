// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant FEE_DENOMINATOR = 10**10;
uint256 constant PRECISION = 10**18;
uint256 constant MAX_COINS = 8;

interface ICurveRegistry {
    function find_pool_for_coins(address _from, address _to, uint256 i) view external returns(address);
    function get_coin_indices(address _pool, address _from, address _to) view external returns(int128, int128, bool);
    function get_balances(address _pool) view external returns (uint256[MAX_COINS] memory);
    function get_rates(address _pool) view external returns (uint256[MAX_COINS] memory);
    function get_A(address _pool) view external returns (uint256);
    function get_fees(address _pool) view external returns (uint256, uint256);
    function get_coins(address _pool) view external returns (address[MAX_COINS] memory);
}