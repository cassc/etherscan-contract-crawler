// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMuutariumStaking {
  event Stake(
    address indexed contractAddress,
    address indexed staker,
    uint256 indexed tokenId
  );

  event Unstake(
    address indexed contractAddress,
    address indexed staker,
    uint256 indexed tokenId
  );

  enum StakingStatus {
    NONE,
    STAKE,
    UNSTAKE,
    ALL
  }

  struct StakingInfos {
    address owner;
    uint256 stakedAt;
  }

  struct CollectionInfos {
    uint256 numberStaked;
    StakingStatus status;
  }
}