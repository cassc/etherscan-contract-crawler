pragma solidity 0.6.12;

interface IStakingRewards {
  function rewardPerToken() external view returns (uint);

  function stake(uint amount) external;

  function withdraw(uint amount) external;

  function getReward() external;
}