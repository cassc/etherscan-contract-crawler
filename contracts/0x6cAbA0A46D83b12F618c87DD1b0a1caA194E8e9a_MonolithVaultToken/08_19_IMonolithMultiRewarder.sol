pragma solidity >=0.5.0;

interface IMonolithMultiRewarder {
  function getReward(address pool) external;

  function rewardTokens(address pool, uint256 index) external view returns (address rewardToken);

  function rewardTokensLength(address pool) external view returns (uint256 length);

  function isRewardToken(address pool, address rewardToken) external view returns (bool);

  function rewardData(address pool, address rewardToken)
    external view returns (
      uint256 rewardsDuration,
      uint256 periodFinish,
      uint256 rewardRate,
      uint256 lastUpdateTime,
      uint256 rewardPerTokenStored
  );

  function earned(address pool, address account, address _rewardsToken) external view returns (uint256);
}