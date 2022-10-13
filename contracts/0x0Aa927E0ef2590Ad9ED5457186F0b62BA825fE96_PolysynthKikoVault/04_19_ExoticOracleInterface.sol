// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface ExoticOracleInterface {
    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);
    function getHistoricalPrice(address _asset, uint80 _roundId) external view returns (uint256, uint256);
}