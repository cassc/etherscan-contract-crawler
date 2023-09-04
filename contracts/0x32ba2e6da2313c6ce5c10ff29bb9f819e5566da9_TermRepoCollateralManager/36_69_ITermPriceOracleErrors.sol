//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermPriceOracleErrors defines all errors emitted by the PriceOracle.
interface ITermPriceOracleErrors {
    error NoPriceFeed(address tokenAddress);
}