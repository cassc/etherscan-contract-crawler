// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

interface ILotManagerV2RewardsHandler {
  event RewardsClaimed(uint256 rewards, uint256 fees);

  function claimRewards() external returns (uint256 _totalRewards);
  function claimableRewards() external view returns (uint256 _amountOut);
}