// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct PonzuRoundData {
  uint256 currentRoundStartTime;
  uint256 currentRoundDeadline;
  uint256 currentRoundEndTime;
  uint256 currentStoredRewards;
  uint256 currentRoundPrizePool;
  uint256 currentRoundPonzuPool;
  uint256 totalParticipants;
}