// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISale {
    enum TimelineStatus {
        PreRegister,
        Register,
        Prepare,
        Live,
        Fcfs,
        Ended
    }

    enum SaleType {
        Open,
        SoftCap,
        WhitelistOnly,
        LevelsOnly,
        LevelsWL
    }

    struct SaleTimeline {
        uint32 startTime;
        uint32 duration;
        uint32 registerTime;
        uint32 registerDuration;
        // FCFS starts from: end - fcfsDuration
        uint32 fcfsDuration;
        uint32 endTime;
    }

    struct UserState {
        uint256 contributed;
        uint256 balance;
        bool isWhitelisted;
        bool isRegistered;
        bool isLottery;
        bool isLotteryWinner;
        // wlAlloc + fcfsAlloc + levelAlloc
        uint256 totalAlloc;
        uint256 wlAlloc;
        uint256 fcfsAlloc;
        uint256 levelAlloc;
        string tierId;
        uint256 weight;
    }

    struct SaleState {
        TimelineStatus status;
        SaleType saleType;
        // Actual rate is: rate / 1e6
        // 6.123456 actual rate = 6123456 specified rate
        uint64 rate;
        uint64 initRate;
        bool isSoftCap;
        uint256 tokensForSale;
        uint256 tokensSold;
        uint256 raised;
        uint16 participants;
        uint256 firstPurchaseBlockN;
        uint256 lastPurchaseBlockN;
        // Max sell per user in currency
        uint256 minSell;
        // Min contribution per TX in currency
        uint256 maxSell;
        // If 0 – whitelist disabled
        uint16 whitelistedCount;
        // Calculated dynamically
        uint256 totalWhitelistAllocation;
    }

    struct FundingState {
        address fundsReceiver;
        bool fundByTokens;
        IERC20 fundToken;
        // 18 by default
        uint8 currencyDecimals;
    }

    struct WhitelistState {
        mapping(address => bool) isWhitelisted;
        // Special allocations per address
        mapping(address => uint256) userAlloc;
        address[] addresses;
        // How many whitelisted
        uint16 count;
        // Sum of all active special WL allocs
        uint256 totalSpecialAlloc;
    }

    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount);
    event UserRefunded(address indexed beneficiary, uint256 value, uint256 amount);

    function getUserState(address account) external view returns (UserState memory);

    function getSaleState() external view returns (SaleState memory);

    function getSaleTimeline() external view returns (SaleTimeline memory);

    function getSaleTimelineStatus() external view returns (TimelineStatus);

    function getFundingState() external view returns (FundingState memory);

    function getWhitelistedAddresses() external view returns (address[] memory);

    // When buying via network native token
    function buyTokens(address affiliateAddress) external payable;

    // When buying via a fundToken
    function buyTokens(uint256 value, address affiliateAddress) external;

    // MUST be protected
//    function batchAddBalance(address[] calldata accounts, uint256[] calldata values) external;

    // MUST be protected
    function batchSetWLAllocation(uint256 amount, address[] calldata addresses) external;

    // MUST be protected
    function batchAddWL(address[] calldata addresses) external;

    // MUST be protected
//    function batchRemoveWL(address[] calldata addresses) external;

    // MUST be protected
    // [startTime, duration, registerTime, registerDuration, FCFSDuration]
    // Registration time, duration can be 0, then there's no registration at all.
    function setSaleTimeline(uint32[5] calldata _timeline) external;

    // MUST be protected
    function withdrawAll() external;

    // MUST be protected
    function withdrawToken(address token, uint256 amount) external;
}