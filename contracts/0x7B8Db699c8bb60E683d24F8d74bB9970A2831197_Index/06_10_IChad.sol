// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IChad {
    function burn(address from, uint256 amount) external;

    function uniswapV2Pair() external returns (address);
}