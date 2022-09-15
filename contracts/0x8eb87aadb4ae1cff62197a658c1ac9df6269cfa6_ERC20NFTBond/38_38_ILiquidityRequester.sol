// SPDX-License-Identifier: GPLv3
pragma solidity 0.8.13;

interface ILiquidityRequester {
    /**
     * Increments every time money is taking out for lending projects, decrements every time is returned
     */
    function requestLiquidity(address destination, uint256 amount) external returns (uint256);
    function returnLiquidity(uint256 amount) external payable returns (uint256);
}