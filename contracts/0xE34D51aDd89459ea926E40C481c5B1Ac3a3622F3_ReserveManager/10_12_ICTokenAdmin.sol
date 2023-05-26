// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICTokenAdmin {
    function extractReserves(address cToken, uint reduceAmount) external;
}