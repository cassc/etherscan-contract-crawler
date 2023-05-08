// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHamachi {
  // get the RewardAccount of an account
  function getRewardAccount(
    address _account
  )
    external
    view
    returns (
      address account,
      int256 index,
      int256 numInQueue,
      uint256 rewardBalance,
      uint256 withdrawableRewards,
      uint256 totalRewards,
      bool manualClaim
    );

  // claims the withdrawableRewards of the sender
  function claimRewards(bool goHami, uint256 expectedOutput) external;

  function setManualClaim(bool _manual) external;
}