// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IGasPrice {
    function maxGasPrice() external returns (uint);
    function enabled() external returns (bool);
}