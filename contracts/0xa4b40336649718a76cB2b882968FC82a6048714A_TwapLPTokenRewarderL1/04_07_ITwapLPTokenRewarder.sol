// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;
pragma abicoder v2;

interface ITwapLPTokenRewarder {
    struct UserInfo {
        uint256 lpAmount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint256 accumulatedItgrPerShare;
        uint64 lastRewardTimestamp;
        uint64 allocationPoints;
    }

    event Staked(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Unstaked(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyUnstaked(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Claimed(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event PoolAdded(uint256 indexed pid, address indexed lpToken, uint256 allocationPoints);
    event PoolSet(uint256 indexed pid, uint256 allocationPoints);
    event PoolUpdated(
        uint256 indexed pid,
        uint64 lastRewardTimestamp,
        uint256 lpSupply,
        uint256 accumulatedItgrPerShare
    );
    event ItgrPerSecondSet(uint256 itgrPerSecond);
    event StakeDisabledSet(bool stakeDisabled);
    event OwnerSet(address owner);

    function setOwner(address _owner) external;

    function setItgrPerSecond(uint256 _itgrPerSecond, bool withPoolsUpdate) external;

    function setStakeDisabled(bool _disabled) external;

    function poolCount() external view returns (uint256 length);

    function addPool(
        address token,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external;

    function setPoolAllocationPoints(
        uint256 pid,
        uint256 allocationPoints,
        bool withPoolsUpdate
    ) external;

    function updatePool(uint256 pid) external returns (PoolInfo memory pool);

    function updatePools(uint256[] calldata pids) external;

    function updateAllPools() external;

    function stake(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function unstake(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyUnstake(uint256 pid, address to) external;

    function claim(uint256 pid, address to) external;

    function unstakeAndClaim(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function claimable(uint256 pid, address userAddress) external view returns (uint256 _claimable);
}