pragma solidity ^0.6.0;


interface ISigmaRewardsFactory {
/* ==========  Constants  ========== */

  function STAKING_REWARDS_IMPLEMENTATION_ID() external pure returns (bytes32);

/* ==========  Immutables  ========== */

  function poolFactory() external view returns (address);

  function proxyManager() external view returns (address);

  function rewardsToken() external view returns (address);

  function uniswapFactory() external view returns (address);

  function weth() external view returns (address);

  function stakingRewardsGenesis() external view returns (uint256);

/* ==========  Storage  ========== */

  function stakingTokens(uint256) external view returns (address);

/* ==========  Pool Deployment (Permissioned)  ==========  */

  function deployStakingRewardsForPoolUniswapPair(address indexPool, uint88 rewardAmount, uint256 rewardsDuration) external;

/* ==========  Rewards  ========== */

  function notifyRewardAmounts() external;

  function notifyRewardAmount(address stakingToken) external;

  function increaseStakingRewards(address stakingToken, uint88 rewardAmount) external;

  function setRewardsDuration(address stakingToken, uint256 newDuration) external;

/* ==========  Token Recovery  ========== */

  function recoverERC20(address stakingToken, address tokenAddress) external;

/* ==========  Queries  ========== */

  function getStakingTokens() external view returns (address[] memory);

  function getStakingRewards(address stakingToken) external view returns (address);

  function computeStakingRewardsAddress(address stakingToken) external view returns (address);
}