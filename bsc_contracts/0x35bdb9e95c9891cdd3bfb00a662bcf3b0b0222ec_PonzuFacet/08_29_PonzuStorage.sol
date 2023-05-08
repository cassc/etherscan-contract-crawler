// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct PonzuStorage {
  address rewardToken;
  address blackHole;
  uint256 blackHoleShare;
  uint256 startTime;
  uint256 pausedTimeInRound;
  uint256 totalDeposited;
  uint256 currentStoredRewards;
  uint256 roundDuration;
  uint256 depositDeadlineDuration;
  bool receivedRandomNumber;
  uint256 randomNumber;
  address[] participantsList;
  mapping(address => ParticipantDeposit) participantDeposits;
}

struct ParticipantDeposit {
  uint256 timestamp;
  uint256 amount;
}

uint256 constant MAX_DEPOSIT = 5 * 10 ** 24; // 5M tokens
uint256 constant PERCENTAGE_DENOMINATOR = 10000;