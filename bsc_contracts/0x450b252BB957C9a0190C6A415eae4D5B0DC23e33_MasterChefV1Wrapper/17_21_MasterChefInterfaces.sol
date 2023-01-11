// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

interface IMasterChefV1 {
    struct PoolInfo {
        address lpToken;
        uint accSushiPerShare;
        uint lastRewardBlock;
        uint allocPoint;
    }

    function poolInfo(uint poolId) external view returns (PoolInfo memory);

    function poolLength() external view returns (uint);

    function totalAllocPoint() external view returns (uint);

    function deposit(uint _pid, uint _amount) external;

    function withdraw(uint _pid, uint _amount) external;
}

interface IRewarder {
    function rewardToken() external view returns (address);

    function pendingToken(uint _pid, address _user) external view returns (uint);

    function pendingTokens(
        uint256 pid,
        address user,
        uint256 sushiAmount
    ) external view returns (address[] memory, uint256[] memory);

    function userInfo(uint pid, address user) external view returns (uint, uint, uint);
}

interface ISushiSwapMasterChefV2 {
    function lpToken(uint poolId) external view returns (address);

    function poolLength() external view returns (uint);

    function totalAllocPoint() external view returns (uint);

    function deposit(uint _pid, uint _amount, address to) external;

    function withdrawAndHarvest(uint _pid, uint _amount, address to) external;

    function withdraw(uint _pid, uint _amount, address to) external;

    function harvest(uint pid, address to) external;

    function rewarder(uint pid) external view returns (address);

    function userInfo(uint pid, address user) external view returns (uint, int);

    function pendingSushi(uint pid, address user) external view returns (uint);
}

interface IPancakeSwapMasterChefV2 is ISushiSwapMasterChefV2 {
    struct PoolInfo {
        uint accCakePerShare;
        uint lastRewardBlock;
        uint allocPoint;
        uint totalBoostedShare;
        bool isRegular;
    }

    function poolInfo(uint _pid) external view returns (PoolInfo memory);
}