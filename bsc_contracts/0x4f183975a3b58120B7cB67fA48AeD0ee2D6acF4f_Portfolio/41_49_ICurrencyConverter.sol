// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface ICurrencyConverter {
    error InvalidTargetDecimals();

    /// @notice set the exchange rate between WON and USD
    /// @dev the caller is contract keeper
    function setExchangeRate(uint256 _exchangeRate) external;

    /// @notice get the exchange rate between WON and USD
    function getExchangeRate() external returns (uint256, uint256);

    /// @param usdAmount the amount of USD received
    /// @dev constructor guarantees 18 = won decimals >= usd decimals
    /// @return wonAmount the amount of WON to give
    function convertFromUSD(uint256 usdAmount) external view returns (uint256 wonAmount);

    /// @param wonAmount the amount of WON received
    /// @dev constructor guarantees 18 = won decimals >= usd decimals
    /// @return usdAmount the amount of USD to give
    function convertToUSD(uint256 wonAmount) external view returns (uint256 usdAmount);
}