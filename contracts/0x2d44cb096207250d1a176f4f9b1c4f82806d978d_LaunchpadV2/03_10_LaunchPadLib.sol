// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


library LaunchPadLib {

    enum PresaleType {PUBLIC, WHITELISTED, TOKENHOLDERS}
    enum PreSaleStatus {PENDING, INPROGRESS, SUCCEED, FAILED, CANCELED}
    enum RefundType {BURN, WITHDRAW}

    struct PresaleInfo {
        uint id;
        address presaleOwner;
        PreSaleStatus preSaleStatus;
    }

    struct TokenInfo {
        address tokenAddress;
        uint8 decimals;
    }

    struct ParticipationCriteria {
        PresaleType presaleType;
        address criteriaToken;
        uint256 minCriteriaTokens;
        uint256 presaleRate;
        uint8 liquidity;
        uint256 hardCap;
        uint256 softCap;
        uint256 minContribution;
        uint256 maxContribution;
        RefundType refundType;
    }

    struct PresaleTimes {
        uint256 startedAt;
        uint256 expiredAt;
        uint256 lpLockupDuration;
    }

    struct PresalectCounts {
        uint256 accumulatedBalance;
        uint256 contributors;
        uint256 claimsCount;
    }

    struct ContributorsVesting {
        bool isEnabled;
        uint firstReleasePC;
        uint eachCycleDuration;
        uint8 eachCyclePC;
    }

    struct TeamVesting {
        bool isEnabled;
        uint vestingTokens;
        uint firstReleaseDelay;
        uint firstReleasePC;
        uint eachCycleDuration;
        uint8 eachCyclePC;
    }

    struct GeneralInfo {
        string logoURL;
        string websiteURL;
        string twitterURL;
        string telegramURL;
        string discordURL;
        string description;
    }
    

}