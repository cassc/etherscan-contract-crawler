// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IRelativePriceProvider {
    /**
     * @notice get the relative price in WAD
     */
    function getRelativePrice() external view returns (uint256);
}