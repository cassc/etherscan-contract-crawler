// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/// @title V3 Utilities
interface IV3Utilities {
    function suggestBestPoolAtFactory(address factory, address token0, address token1) external view returns(uint16 fee, address poolAddress);
    function suggestBestPool(address token0, address token1) external view returns(uint16 fee, address poolAddress);
}