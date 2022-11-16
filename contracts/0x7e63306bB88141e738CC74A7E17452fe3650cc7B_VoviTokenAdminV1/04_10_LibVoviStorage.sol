// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/IVoviWallets.sol";

library LibVoviStorage {

  bytes32 constant VOVI_STORAGE_POSITION = keccak256("com.voxelville.vovi.storage");

  struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  struct StakingRange {
    uint256 from;
    uint256 to;
    uint256 baseReward;
  }

  struct Reward {
    uint256 tokenId;
    uint256 tokens;
    Coupon coupon;
  }

  struct StakeRequest {
    uint256 tokenId;
    uint256 lastTxDate;
    uint256 listed;
    Coupon coupon;
    uint256 avatar;
    uint256 avatarTxDate;
    uint256 listedAvatar;
    Coupon avatarCoupon;
  }

  struct ClaimRequest {
    uint256 tokenId;
    uint256 lastTxDate;
    uint256 listed;
    Reward multReward;
    Coupon coupon;
    uint256 avatarTxDate;
    uint256 listedAvatar;
    Coupon avatarCoupon;
  }
  
  struct VoviStorage {

    mapping(uint256 => uint256)  lastTxDates;
    mapping(uint256 => uint256)  lastAvatarTxDates;

    StakingRange[]  ranges;

    IERC721  voxelVilleContract;
    IERC721  voxelVilleAvatarsContract;
    IVoviWallets  voviWalletsContract;
    address  adminSigner;
    mapping(uint256 => uint256)  stakedAvatars;
    mapping(uint256 => uint256)  stakedAvatarsReverse;
    

    uint256 rewardsEnd;
    bool finalizedRewardsEnd;


    mapping(uint256 => uint256) lastClaimedBlockForToken;
    mapping(address => EnumerableSet.UintSet) stakedTokens;

    mapping(uint256 => bool) claimedHolderRewards;

    uint256 reentrancyStatus;

    bool paused;

    mapping(uint256 => bool) bulkRewardClaimed;

    uint256 dailyBlockAverage;
    uint256 bulkRewardDays;
  }
  


  function voviStorage() internal pure returns (VoviStorage storage vs) {
    bytes32 position = VOVI_STORAGE_POSITION;
    assembly {
      vs.slot := position
    }
  }
}