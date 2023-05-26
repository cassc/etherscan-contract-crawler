// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface INftStaking {
  enum PlanId {
    plan0monthsLock,
    plan1monthsLock,
    plan3monthsLock,
    plan6monthsLock
  }

  struct RewardPeriod {
    uint256 dailyReward;
    uint256 validFrom;
  }

  struct Plan {
    uint64 lockDuration;
    uint16 dailyRewardPercentage;
  }

  struct NFT {
    address nftContract;
    uint256 tokenId;
  }

  struct NFTWithPlanId {
    address nftContract;
    uint256 tokenId;
    PlanId planId;
  }

  struct NFTStake {
    address user;
    PlanId planId;
    uint64 stakedAt;
    uint64 unstakedAt;
    uint256 rewardClaimed;
  }

  struct UserNFTStake {
    address nftContract;
    uint256 tokenId;
    PlanId planId;
    uint64 stakedAt;
    uint64 unstakedAt;
    uint256 rewardClaimed;
  }

  struct WhitelistedContract {
    address contractAddress;
    RewardPeriod[] rewardPeriods;
  }

  event Staked(
    address indexed user,
    PlanId planId,
    address nftContract,
    uint256 tokenId
  );

  event Unstaked(
    address indexed user,
    PlanId planId,
    address nftContract,
    uint256 tokenId
  );

  event RewardClaimed(
    address indexed user,
    PlanId planId,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 amount
  );

  event WithdrawAnnounced(uint256 timestamp);
  event WithdrawCancelled();
  event Withdrawn(uint256 amount);
}