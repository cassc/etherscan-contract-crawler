// SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.0;

struct StakingArgs {
  address token;
  address aggregator;
  uint32 subscribeStageFrom;
  uint32 subscribeStagePeriod;
  uint32 earnStagePeriod;
  uint32 claimStagePeriod;
  uint64 maxTotalStake;
  uint64 maxUserStake;
  uint64 earningsQuota;
}

struct StakingData {
  address token;
  address aggregator;
  uint32 subscribeStageFrom;
  uint32 subscribeStageTo;
  uint32 earnStageTo;
  uint32 claimStageTo;
  uint64 currentTotalDeposit;
  uint64 maxTotalStake;
  uint64 maxUserStake;
  uint64 earningsQuota;
  uint64 earningPercent;
  uint64 unusedQuota;
}

interface IStaking {
  function increaseDeposit(address from, uint256 value) external;

  function withdrawDeposit(address from) external;

  function claim(address from) external;

  function getData() external view returns (StakingData memory);
}

contract StakingTypes {
  event DepositIncreased(address indexed user, uint256 value);
  event DepositWithdrawn(address indexed user);
  event Claimed(address indexed user, uint256 total);

  error TokenTotalSupplyExceedsUint64();
  error DepositTooEarly();
  error DepositTooLate();
  error BalanceTooLow();
  error MaxUserStakeExceeded();
  error MaxTotalStakeExceeded();
  error ZeroBalance();
  error TooEarlyForClaimStage();
  error ZeroValue();
  error ZeroUnusedQuota();
  error UnusedQuotaAlreadyTransferred();
  error SubscribeStageNotFinished();
  error ClaimStageNotFinished();
  error CallerIsNotAggregator();
}