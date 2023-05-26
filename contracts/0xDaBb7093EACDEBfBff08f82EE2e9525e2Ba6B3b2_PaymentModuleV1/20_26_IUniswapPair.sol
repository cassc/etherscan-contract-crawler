// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IUniswapPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);
}