// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IBurner {
    function burn(address to, address token, uint amount, uint amountOutMin, address[] calldata path) external;
}