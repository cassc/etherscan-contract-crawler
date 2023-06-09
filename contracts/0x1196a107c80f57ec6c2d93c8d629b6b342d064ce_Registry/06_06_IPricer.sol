// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPricer {
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee
    ) external pure returns (uint);
}