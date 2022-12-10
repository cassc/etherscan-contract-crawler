// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IGasPrice {
    function maxGasPrice() external returns (uint);
}