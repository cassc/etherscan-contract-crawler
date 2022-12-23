// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
    }

    struct PoolInfo {
        uint256 accCakePerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool isRegular;
    }

    function MASTER_CHEF() external view returns (address);
    function MASTER_PID() external view returns (address);
    function CAKE() external view returns (address);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);
    function userInfo(uint256 arg1, address arg2) external view returns (UserInfo memory);
    function whiteList(address pid) external view returns (bool);
    function lpToken(uint256 pid) external view returns (address);
    function poolLength() external view returns (uint256);
    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function massUpdatePools() external;
    function updatePool(uint256 _pid) external returns (PoolInfo memory pool);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function harvestFromMasterChef() external;
    function emergencyWithdraw(uint256 _pid) external;  
}