pragma solidity >=0.8.17;
// SPDX-License-Identifier: GPL-2.0-or-later
interface IUniswapV3Pool {
    function token0() external view returns(address);
    function token1() external view returns(address);
    function fee() external view returns(uint24);
    function tickSpacing() external view returns(int24);
}