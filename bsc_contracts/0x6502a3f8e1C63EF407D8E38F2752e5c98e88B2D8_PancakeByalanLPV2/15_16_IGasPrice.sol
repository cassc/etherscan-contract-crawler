//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IGasPrice {
    function maxGasPrice() external returns (uint256);
}