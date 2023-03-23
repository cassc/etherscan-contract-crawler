// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IMasterChef2 {
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

  function totalRegularAllocPoint() external view returns (uint256);

  function totalSpecialAllocPoint() external view returns (uint256);

  function cakePerBlock(bool _isRegular) external view returns (uint256 amount);

  // solhint-disable-next-line func-name-mixedcase
  function CAKE() external view returns (address);

  function poolLength() external view returns (uint256);

  function poolInfo(uint256 pool) external view returns (PoolInfo memory);

  function lpToken(uint256 pool) external view returns (address);

  function userInfo(uint256 pool, address user) external view returns (UserInfo memory);

  function pendingCake(uint256 pool, address user) external view returns (uint256);

  function deposit(uint256 pool, uint256 amount) external;

  function withdraw(uint256 pool, uint256 amount) external;

  function emergencyWithdraw(uint256 pool) external;
}