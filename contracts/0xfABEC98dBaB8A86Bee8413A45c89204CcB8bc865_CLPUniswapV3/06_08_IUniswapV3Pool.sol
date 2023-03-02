// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

interface IUniswapV3Pool {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);
}