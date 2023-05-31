// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISwapper {
    function buy(uint256 amount) external returns (uint256);

    function sell(uint256 amount) external returns (uint256);
}