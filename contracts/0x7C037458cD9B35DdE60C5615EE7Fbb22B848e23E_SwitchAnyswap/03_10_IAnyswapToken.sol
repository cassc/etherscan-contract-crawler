// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IAnyswapToken {
    function underlying() external returns (address);
}