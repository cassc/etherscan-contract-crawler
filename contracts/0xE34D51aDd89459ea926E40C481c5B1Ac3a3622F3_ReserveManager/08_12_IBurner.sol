// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBurner {
    function burn(address coin) external returns (uint);
}