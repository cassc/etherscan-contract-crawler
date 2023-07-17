// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IPair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}