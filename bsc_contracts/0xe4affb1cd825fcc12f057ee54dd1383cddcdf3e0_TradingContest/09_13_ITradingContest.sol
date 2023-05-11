// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

struct BatchInfo {
    uint128 rewardTokens;
    uint64 startTime;
    uint64 endTime;
    uint64 startVestingTime;
    uint64 vestingDuration;
    uint128 totalWeight;
    bool leaderUpdated;
}

struct LeaderInfo {
    uint128 weight;
    uint128 claimed;
    uint256 totalPoint;
    uint8 index;
}

struct LeaderInfoView {
    address trader;
    uint128 rewardTokens;
    uint128 claimed;
    uint256 totalPoint;
    uint8 index;
}

struct ContestResult {
    address trader;
    uint8 index;
    uint256 totalPoint;
}

interface ITradingContest {
    function batchDuration() external returns (uint64);

    function record(address _user, uint256 _value) external;

    function addReward(uint256 _rewardTokens) external;

    function addExtraReward(uint64 _batchId, uint256 _rewardTokens) external;

    function nextBatch() external;
}