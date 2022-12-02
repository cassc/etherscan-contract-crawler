// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaking {
  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event EscrowDurationUpdated(uint256 _previousDuration, uint256 _newDuration);
  event RewardDistributorUpdated(address indexed distributor, bool approved);

  // Views
  function balanceOf(address account) external view returns (uint256);

  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function getRewardForDuration() external view returns (uint256);

  function stakingToken() external view returns (IERC20);

  function rewardsToken() external view returns (IERC20);

  function escrowDuration() external view returns (uint256);

  function rewardsDuration() external view returns (uint256);

  function paused() external view returns (bool);

  // Mutative
  function stake(uint256 amount) external;

  function stakeFor(uint256 amount, address account) external;

  function withdraw(uint256 amount) external;

  function withdrawFor(
    uint256 amount,
    address owner,
    address receiver
  ) external;

  function getReward() external;

  function exit() external;

  function notifyRewardAmount(uint256 reward) external;

  function setEscrowDuration(uint256 duration) external;

  function setRewardsDuration(uint256 duration) external;

  function pauseContract() external;

  function unpauseContract() external;
}