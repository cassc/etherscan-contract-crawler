// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// Imported from:
/// https://github.com/notional-finance/contracts-v2/blob/23a3d5fcdba8a2e2ae6b0730f73eed810484e4cc/contracts/global/Types.sol
/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalAssetCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
}

/// Imported from:
/// https://github.com/notional-finance/contracts-v2/blob/23a3d5fcdba8a2e2ae6b0730f73eed810484e4cc/contracts/global/Types.sol
/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    // RATE_PRECISION is defined as 1e9 in the constants contract deployed here:
    // https://github.com/notional-finance/contracts-v2/blob/23a3d5fcdba8a2e2ae6b0730f73eed810484e4cc/contracts/global/Constants.sol
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

interface INotionalView {
    /// @notice Returns a single market
    function getMarket(
        uint16 currencyId_,
        uint256 maturity_,
        uint256 settlementDate_
    ) external view returns (MarketParameters memory);

    function getActiveMarkets(uint16 currencyId)
        external
        view
        returns (MarketParameters[] memory);
}