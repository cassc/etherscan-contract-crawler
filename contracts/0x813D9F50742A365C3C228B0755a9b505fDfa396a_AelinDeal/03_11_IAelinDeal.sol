// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IAelinDeal {
    struct DealData {
        address underlyingDealToken;
        uint256 underlyingDealTokenTotal;
        uint256 vestingPeriod;
        uint256 vestingCliffPeriod;
        uint256 proRataRedemptionPeriod;
        uint256 openRedemptionPeriod;
        address holder;
        uint256 maxDealTotalSupply;
        uint256 holderFundingDuration;
    }

    struct Timeline {
        uint256 period;
        uint256 start;
        uint256 expiry;
    }
}