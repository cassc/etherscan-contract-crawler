// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IUnknownProxy {
  function claimStakingRewards() external payable;

  function claimStakingRewards(address stakingPool) external payable;

  function depositLpAndStake(address conePoolAddress, uint256 amount) external;

  function unstakeLpAndWithdraw(address conePoolAddress, uint256 amount) external;

  function unstakeLpWithdrawAndClaim(address conePoolAddress, uint256 amount) external;
}