/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../libraries/Decimal.sol";

/**
 * @title Oracle Interface
 **/
interface IOracle {
    function capture() external returns (Decimal.D256 memory, Decimal.D256 memory);
}