// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface IStakedAave {

  event Staked(
    address indexed from,
    address indexed to,
    uint256 assets,
    uint256 shares
  );
  event Redeem(
    address indexed from,
    address indexed to,
    uint256 assets,
    uint256 shares
  );

  event RewardsAccrued(address user, uint256 amount);
  event RewardsClaimed(address indexed from, address indexed to, uint256 amount);

  event Cooldown(address indexed user);

  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function getTotalRewardsBalance(address staker) external view returns (uint256);
}