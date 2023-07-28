// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

/// @title IDexFactory
/// @author gotbit

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}