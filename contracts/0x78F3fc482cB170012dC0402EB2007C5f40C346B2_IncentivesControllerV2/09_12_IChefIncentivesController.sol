// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOnwardIncentivesController.sol";

interface IChefIncentivesController {
  struct UserInfo {
    uint amount;
    uint rewardDebt;
  }
  struct PoolInfo {
    uint totalSupply;
    uint allocPoint; // How many allocation points assigned to this pool.
    uint lastRewardTime; // Last second that reward distribution occurs.
    uint accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
    IOnwardIncentivesController onwardIncentives;
  }
  function mintedTokens() external view returns (uint);
  function rewardsPerSecond() external view returns (uint);
  function startTime() external view returns(uint);
  function poolInfo(address token) external view returns(PoolInfo memory);
  function registeredTokens(uint idx) external view returns(address);
  function poolLength() external view returns(uint);
  function userInfo(address token, address user) external view returns(UserInfo memory);
  function userBaseClaimable(address user) external view returns(uint);
  function handleAction(address user, uint256 userBalance, uint256 totalSupply) external;
  function addPool(address _token, uint256 _allocPoint) external;
  function claim(address _user, address[] calldata _tokens) external;
  function setClaimReceiver(address _user, address _receiver) external;
}