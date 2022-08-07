// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

struct LiquidityStatus {
    uint256 collateralValue;
    uint256 liabilityValue;
    uint256 numBorrows;
    bool borrowIsolated;
}

struct AssetConfig {
    address eTokenAddress;
    bool borrowIsolated;
    uint32 collateralFactor;
    uint32 borrowFactor;
    uint24 twapWindow;
}

// Query
struct Query {
    address eulerContract;
    address account;
    address[] markets;
}

// Response
struct ResponseMarket {
    // Universal
    address underlying;
    string name;
    string symbol;
    uint8 decimals;
    address eTokenAddr;
    address dTokenAddr;
    address pTokenAddr;
    AssetConfig config;
    uint256 poolSize;
    uint256 totalBalances;
    uint256 totalBorrows;
    uint256 reserveBalance;
    uint32 reserveFee;
    uint256 borrowAPY;
    uint256 supplyAPY;
    // Pricing
    uint256 twap;
    uint256 twapPeriod;
    uint256 currPrice;
    uint16 pricingType;
    uint32 pricingParameters;
    address pricingForwarded;
    // Account specific
    uint256 underlyingBalance;
    uint256 eulerAllowance;
    uint256 eTokenBalance;
    uint256 eTokenBalanceUnderlying;
    uint256 dTokenBalance;
    LiquidityStatus liquidityStatus; //for asset
}

struct Response {
    uint256 timestamp;
    uint256 blockNumber;
    ResponseMarket[] markets;
    address[] enteredMarkets;
}

interface IEulerMarkets {
    function underlyingToEToken(address underlying) external view returns (address);
}

interface IEToken {
    function balanceOfUnderlying(address account) external view returns (uint256);
}

interface IEulerGeneralView {
    function doQueryBatch(Query[] memory qs) external view returns (Response[] memory r);

    function doQuery(Query memory q) external view returns (Response memory r);
}

interface IEulerExecute {
    function liquidity(address account) external view returns (LiquidityStatus memory status);
}

interface IEulerDistributor {
    function claimed(address user, address token) external view returns (uint256 claimedAmount);
}