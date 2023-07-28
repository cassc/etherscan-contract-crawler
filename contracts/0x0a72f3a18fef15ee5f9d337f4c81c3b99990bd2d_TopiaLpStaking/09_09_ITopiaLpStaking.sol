// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITopiaLpStaking {
    event LpTokensStaked(address indexed user, uint16 userStakeIndex, uint256 amount, uint256 lockupTime);
    event LpTokensUnstaked(address indexed user, uint16 userStakeIndex, uint256 amount, uint256 reward);
    event LpTokensUnstakeForfeited(address indexed user, uint16 userStakeIndex, uint256 amount);
    event RewardsSet(uint32 start, uint32 end, uint256 rate);
    event RewardsPerWeightUpdated(uint256 accumulated);
    event LockupIntervalAdded(uint8 lockupIntervalIndex, uint32 interval, uint8 multiplier);
    event RewardsTokenSet(address rewardsTokenAddress);
    event UniswapPairSet(address uniswapPairAddress);

    error IntervalsMismatch();
    error LPAmountZero();
    error AlreadyUnstaked();
    error LockupTimeUnmet();
    error StakedPositionsRequired();
    error RewardsAlreadySet();
    error InvalidStart();
    error InvalidStartEnd();
    error InvalidRewardRate();

    struct RewardsPeriod {
        uint32 start; // reward start time, in unix epoch
        uint32 end; // reward end time, in unix epoch
    }

    struct RewardsPerWeight {
        uint256 totalWeight;
        uint96 accumulated;
        uint32 lastUpdated;
        uint96 rate;
    }

    struct UserStake {
        uint256 lpAmount;
        uint96 checkpoint;
        uint32 startedAt;
        uint8 lockupIntervalIndex;
        bool claimed;
        bool forfeited;
    }

    // view functions
    function estimateStakeReward(uint256 _lpAmount, uint8 _lockupIntervalIndex) external view returns (uint256);

    function getUserStakeReward(address _user, uint16 _userStakeIndex) external view returns (uint256);

    function getUserStakeRewards(
        address _user,
        uint16[] calldata _userStakeIndexes
    ) external view returns (uint256[] memory);

    function getUserStake(address _user, uint16 _userStakeIndex) external view returns (UserStake memory);

    function getUserStakes(address _user) external view returns (UserStake[] memory);

    function getUserStakesCount(address _user) external view returns (uint256);

    function getLockupIntervals() external view returns (uint32[] memory);

    function getLockupIntervalsCount() external view returns (uint8);

    function getLockupIntervalMultipliers() external view returns (uint8[] memory);

    // public functions
    function stake(uint256 _lpAmount, uint8 _lockupIntervalIndex) external;

    function unstakeClaim(uint16 _userStakeIndex) external;

    function unstakeForfeit(uint16 _userStakeIndex) external;
}