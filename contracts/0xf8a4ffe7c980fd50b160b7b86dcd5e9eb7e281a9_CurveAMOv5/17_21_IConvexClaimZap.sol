// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexClaimZap {
  function chefRewards() external view returns (address);
  function claimRewards(address[] calldata rewardContracts, uint256[] calldata chefIds, bool claimCvx, bool claimCvxStake, bool claimcvxCrv, uint256 depositCrvMaxAmount, uint256 depositCvxMaxAmount) external;
  function crv() external view returns (address);
  function crvDeposit() external view returns (address);
  function cvx() external view returns (address);
  function cvxCrv() external view returns (address);
  function cvxCrvRewards() external view returns (address);
  function cvxRewards() external view returns (address);
  function owner() external view returns (address);
  function setApprovals() external;
  function setChefRewards(address _rewards) external;
}