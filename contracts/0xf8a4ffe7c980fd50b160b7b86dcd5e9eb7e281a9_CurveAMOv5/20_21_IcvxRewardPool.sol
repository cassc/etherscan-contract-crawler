// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IcvxRewardPool {
  function FEE_DENOMINATOR() external view returns (uint256);
  function addExtraReward(address _reward) external;
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function crvDeposits() external view returns (address);
  function currentRewards() external view returns (uint256);
  function cvxCrvRewards() external view returns (address);
  function cvxCrvToken() external view returns (address);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward(bool _stake) external;
  function getReward(address _account, bool _claimExtras, bool _stake) external;
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external;
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external;
  function stakeAll() external;
  function stakeFor(address _for, uint256 _amount) external;
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 _amount, bool claim) external;
  function withdrawAll(bool claim) external;
}