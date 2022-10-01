// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IQuasiStaking {
  struct DistributionData {
    uint256 startTime;
    uint256 endTime;
    uint256 amount;
  }

  function getDistributionData(uint256 index) external view returns (DistributionData memory);

  function rewardsUnpaid(address nft, uint256 id) external view returns (uint256);

  function batchRewardsUnpaid(address[] memory nfts, uint256[] memory ids) external view returns (uint256);

  function addDistribution(uint256 duration, uint256 amount) external;

  function register(address nft, uint256 id) external;

  function batchRegister(address[] memory nfts, uint256[] memory ids) external;

  function getRewards(address nft, uint256 id) external;

  function batchGetRewards(address[] memory nfts, uint256[] memory ids) external;

  function settleRewardsToken() external;
}