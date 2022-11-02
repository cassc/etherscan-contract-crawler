// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAnyswapToken {
    function underlying() external returns (address);
}