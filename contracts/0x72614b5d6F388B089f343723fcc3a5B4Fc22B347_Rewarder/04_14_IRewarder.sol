// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewarder {
    struct UserInfo {
        uint256 rewardableDeposit;
        uint256 lifetimeRewardPerOneEtherOfDeposit;
        uint256 pendingReward;
    }

    struct PoolInfo {
        uint256 lifetimeRewardPerOneEtherOfDeposit;
        uint256 lastRewardBlock;
        uint256 rewardPerBlockPerOneEtherOfDeposit;
        uint256 limitPerBlockPerOneEtherOfDeposit;
    }

    event UpdateUser(address indexed user, uint256 indexed poolId, uint256 shares);
    event Claim(address indexed user, uint256 indexed poolId, uint256 rewardAmount, address to);
    event AddPool(uint256 indexed poolId, uint256 rewards);
    event SetFixedRewardPerBlock(uint256 rewardPerBlock);
    event SetFloatingRewardPerBlock(uint256 rewardRate);
    event UpdatePoolRewards(uint256 indexed poolId, uint256 newRewards);
    event UpdatePoolsRewards(uint256[] poolIds, uint256[] newRewards);
    event UpdatePoolLimit(uint256 indexed poolId, uint256 newLimit);
    event UpdatePool(uint256 indexed poolId, uint256 lastRewardBlock, uint256 totalShares, uint256 lifetimeRewardPerExashare); 
    event UpdateDev(address newDev); 
    event UpdateDao(address newDao);
    function poolCount() external view returns (uint256 pools);
    function pendingReward(uint256 poolId, address userAddress) external view returns (uint256 _pendingReward);

    function updateUser(uint256 poolId, address user, uint256 rewardableDeposit) external;
    function claim(uint256 poolId, address user, address to) external;
    function addBulk(uint256[] memory rewardsPerBlockPerOneEther, uint256[] memory poolIdList, uint256[] memory poolLimits) external;
    function updatePoolRewards(uint256 poolId, uint256 newRewardPerBlockPerEther) external;
    function massUpdatePoolRewards(uint256[] memory poolIds, uint256[] memory newRewardsPerBlockPerEther) external;
    function updatePoolLimit(uint256 poolId, uint256 newLimitPerBlockPerEther) external;
    function massUpdatePoolLimits(uint256[] memory poolIds, uint256[] memory newLimitsPerBlockPerEther) external;
    function massUpdatePools(uint256[] calldata poolIdList) external;
    function updatePool(uint256 poolId) external returns (PoolInfo memory pool, uint256 rewardableDeposits);

    function distributeFee() external;
    function updateDev(address newDev) external;
    function updateDao(address newDao) external;
    
}