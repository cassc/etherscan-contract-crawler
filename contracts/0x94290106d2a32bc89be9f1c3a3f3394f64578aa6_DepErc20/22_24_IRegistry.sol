// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IRegistry {
    // Get a list of decimal places for each coin within a pool.
    function get_decimals(address pool) external view returns (uint[8] memory);
    // Perform an token exchange using a specific pool.
    function exchange(address _pool, address _from, address _to, uint _amound, uint _expected, address _receiver) external returns (uint);
    // Get the current number of coins received in an exchange.
    // Returns the quantity of _to to be received in the exchange.
    function get_exchange_amount(address _pool, address _from, address _to, uint _amount) external view returns (uint);
}