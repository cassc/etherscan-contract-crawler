pragma solidity ^0.8.13;

interface ILiquidityGauge {
  function deposit(uint256 _value) external;
  function withdraw(uint256 _value) external;
  function user_checkpoint(address addr) external;
  function integrate_fraction(address user) external returns (uint256);
  function claim_rewards() external;
  function claimable_reward(address account, address token) external view returns (uint256);
  function claimable_tokens(address account) external view returns (uint256);
  function balanceOf(address account) external returns (uint256);
  function totalSupply() external returns (uint256);
}