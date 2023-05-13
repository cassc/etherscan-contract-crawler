// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IMultiMerkleDistributor {

  struct ClaimParams {
    uint256 questID;
    uint256 period;
    uint256 index;
    uint256 amount;
    bytes32[] merkleProof;
  }

  event Claimed(
    uint256 indexed questID,
    uint256 indexed period,
    uint256 index,
    uint256 amount,
    address rewardToken,
    address indexed account
  );
  event NewPendingOwner(
    address indexed previousPendingOwner,
    address indexed newPendingOwner
  );
  event NewQuest(uint256 indexed questID, address rewardToken);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  event QuestPeriodUpdated(
    uint256 indexed questID,
    uint256 indexed period,
    bytes32 merkleRoot
  );

  function acceptOwnership() external;

  function addQuest(uint256 questID, address token) external returns (bool);

  function addQuestPeriod(
    uint256 questID,
    uint256 period,
    uint256 totalRewardAmount
  ) external returns (bool);

  function claim(
    uint256 questID,
    uint256 period,
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external;

  function claimQuest(
    address account,
    uint256 questID,
    ClaimParams[] memory claims
  ) external;

  function emergencyUpdateQuestPeriod(
    uint256 questID,
    uint256 period,
    uint256 addedRewardAmount,
    bytes32 merkleRoot
  ) external returns (bool);

  function getClosedPeriodsByQuests(uint256 questID)
  external
  view
  returns (uint256[] memory);

  function isClaimed(
    uint256 questID,
    uint256 period,
    uint256 index
  ) external view returns (bool);

  function multiClaim(
    address account,
    ClaimParams[] memory claims
  ) external;

  function owner() external view returns (address);

  function pendingOwner() external view returns (address);

  function questBoard() external view returns (address);

  function questClosedPeriods(uint256, uint256)
  external
  view
  returns (uint256);

  function questMerkleRootPerPeriod(uint256, uint256)
  external
  view
  returns (bytes32);

  function questRewardToken(uint256) external view returns (address);

  function questRewardsPerPeriod(uint256, uint256)
  external
  view
  returns (uint256);

  function recoverERC20(address token) external returns (bool);

  function renounceOwnership() external;

  function rewardTokens(address) external view returns (bool);

  function transferOwnership(address newOwner) external;

  function updateQuestPeriod(
    uint256 questID,
    uint256 period,
    uint256 totalAmount,
    bytes32 merkleRoot
  ) external returns (bool);
}