// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IUniV2Pool {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
}