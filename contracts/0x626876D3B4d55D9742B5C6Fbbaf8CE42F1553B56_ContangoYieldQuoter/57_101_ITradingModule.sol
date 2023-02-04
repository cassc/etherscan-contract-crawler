// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @dev https://github.com/notional-finance/leveraged-vaults/blob/master/interfaces/trading/ITradingModule.sol
interface ITradingModule {
    event PriceOracleUpdated(address token, address oracle);
    event MaxOracleFreshnessUpdated(uint32 currentValue, uint32 newValue);

    function setPriceOracle(address token, AggregatorV2V3Interface oracle) external;
    function getOraclePrice(address inToken, address outToken) external view returns (int256 answer, int256 decimals);
}