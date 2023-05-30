// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVendorOracle {
    error ZeroAddress();
    error InvalidParameters();
    error FeedAlreadySet();
    function getPriceUSD(address base) external view returns (int256);
}