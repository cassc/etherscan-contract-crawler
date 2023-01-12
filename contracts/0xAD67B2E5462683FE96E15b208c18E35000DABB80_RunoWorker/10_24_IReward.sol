// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../types/Type.sol";

interface IReward {
  function setRewardStartAt(
    uint256 rewardStartAt_
  ) external;

  function getRewardStartAt(
  ) external view returns (uint256);

  function getTokenInfo(
    uint256[] memory tokenId_
  ) external view returns (uint256[] memory, uint256[] memory, uint256[] memory);

  function run(
    uint256[] memory tokenIds_
  ) external;

  function stop(
    uint256[] memory tokenIds_
  ) external;

  function getClaimableRewards(
    uint256 tokenId_
  ) external view returns (uint256);

  function claimReward(
    uint256 tokenId_
  ) external payable;

  function claimRewardAll(
    uint256[] memory tokenIds_
  ) external payable;

  function setDailyRewardByMonth(
    uint256 month_,
    uint256 reward_
  ) external;

  function getCurrentRewardTable(
  ) external view returns (uint256[] memory);

  function initClaimed(
    uint256 tokenId_
  ) external;

  function destroy(
    address payable to_
  ) external;
}