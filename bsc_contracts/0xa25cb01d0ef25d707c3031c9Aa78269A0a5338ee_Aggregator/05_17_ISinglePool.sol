// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ISinglePool {
    struct PoolInfo {
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    struct UserInfo {
        uint256 totalDepositTokens;
        uint256 totalDepositDollarValue;
        uint256 totalGGYMNET;
        uint256 level;
        uint256 depositId;
        uint256 totalClaimt;
    }

    function poolInfo() external view returns(PoolInfo memory);
    function totalClaimtInPool() external view returns (uint256);
    function totalGymnetLocked() external view returns (uint256);
    function getRewardPerBlock() external view returns (uint256);
    function totalGymnetUnlocked() external view returns (uint256);
    function totalGGymnetInPoolLocked() external view returns (uint256);
    function totalLockedTokens(address _user) external view returns (uint256);
    function userTotalGGymnetLocked(address _user) external view returns (uint256);
    function userInfo(address) external view returns(UserInfo memory);
}