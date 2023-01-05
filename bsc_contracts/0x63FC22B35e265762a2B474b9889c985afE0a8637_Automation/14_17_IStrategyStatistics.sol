// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
struct XTokenInfo {
    string name;
    address xToken;
    uint256 totalSupply;
    uint256 totalSupplyUSD;
    uint256 lendingAmount;
    uint256 lendingAmountUSD;
    uint256 borrowAmount;
    uint256 borrowAmountUSD;
    uint256 borrowLimitUSD;
    uint256 underlyingBalance;
    uint256 priceUSD;
}

struct FarmingPairInfo {
    uint256 index;
    address lpToken;
    uint256 farmingAmount;
    uint256 rewardsAmount;
    uint256 rewardsAmountUSD;
}

struct WalletInfo {
    string name;
    address token;
    uint256 balance;
    uint256 balanceUSD;
}

struct PriceInfo {
    address token;
    uint256 priceUSD;
}

interface IStrategyStatistics {
    function getStrategyAvailable(address logic, uint8 strategyType)
        external
        view
        returns (uint256 totalAvailableUSD);

    function getStrategyBalance(address logic, uint8 strategyType)
        external
        view
        returns (
            uint256 totalBorrowLimitUSD,
            uint256 totalSupplyUSD,
            uint256 totalBorrowUSD,
            uint256 percentLimit,
            XTokenInfo[] memory xTokensInfo
        );
}