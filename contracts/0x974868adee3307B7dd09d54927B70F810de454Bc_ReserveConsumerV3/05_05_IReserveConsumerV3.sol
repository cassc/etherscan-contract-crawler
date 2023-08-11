// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IReserveConsumerV3 {

    /**
     * Returns the latest price
     */
    function getLatestReserve() external view returns (int);
    /**
     * Returns the decimals of the price
     */
    function decimals() external view returns (uint8);
}