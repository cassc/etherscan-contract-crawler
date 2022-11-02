// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IConvexRewards {
  // strategy's staked balance in the synthetix staking contract
  function balanceOf(address account) external view returns (uint256);

  // read how much claimable CRV a strategy has
  function earned(address account) external view returns (uint256);

  // stake a convex tokenized deposit
  function stake(uint256 _amount) external returns (bool);

  // withdraw to a convex tokenized deposit, probably never need to use this
  function withdraw(uint256 _amount, bool _claim) external returns (bool);

  // withdraw directly to curve LP token, this is what we primarily use
  function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

  // claim rewards, with an option to claim extra rewards or not
  function getReward(address _account, bool _claimExtras) external returns (bool);
}