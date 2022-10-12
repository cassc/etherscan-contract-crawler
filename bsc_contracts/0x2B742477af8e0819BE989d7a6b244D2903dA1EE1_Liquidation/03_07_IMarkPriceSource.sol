/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;

interface IMarkPriceSource {
    /// @notice Return mark price. Revert if data not available.
    /// @return price is a 1e18 based decimal.
    function getMarkPrice() external view returns (uint256 price);
}