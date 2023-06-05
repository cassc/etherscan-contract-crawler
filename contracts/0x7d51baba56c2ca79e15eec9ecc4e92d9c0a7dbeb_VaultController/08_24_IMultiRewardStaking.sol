// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15
pragma solidity ^0.8.15;

import { IERC4626Upgradeable as IERC4626, IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";
import { IOwned } from "./IOwned.sol";
import { IPermit } from "./IPermit.sol";
import { IPausable } from "./IPausable.sol";
import { IMultiRewardEscrow } from "./IMultiRewardEscrow.sol";

/// @notice The whole reward and accrual logic is heavily based on the Fei Protocol's Flywheel contracts.
/// https://github.com/fei-protocol/flywheel-v2/blob/main/src/rewards/FlywheelStaticRewards.sol
/// https://github.com/fei-protocol/flywheel-v2/blob/main/src/FlywheelCore.sol
struct RewardInfo {
  /// @notice scalar for the rewardToken
  uint64 ONE;
  /// @notice Rewards per second
  uint160 rewardsPerSecond;
  /// @notice The timestamp the rewards end at
  /// @dev use 0 to specify no end
  uint32 rewardsEndTimestamp;
  /// @notice The strategy's last updated index
  uint224 index;
  /// @notice The timestamp the index was last updated at
  uint32 lastUpdatedTimestamp;
}

struct EscrowInfo {
  /// @notice Percentage of reward that gets escrowed in 1e18 (1e18 = 100%, 1e14 = 1 BPS)
  uint192 escrowPercentage;
  /// @notice Duration of the escrow in seconds
  uint32 escrowDuration;
  /// @notice A cliff before the escrow starts in seconds
  uint32 offset;
}

interface IMultiRewardStaking is IERC4626, IOwned, IPermit, IPausable {
  function addRewardToken(
    IERC20 rewardToken,
    uint160 rewardsPerSecond,
    uint256 amount,
    bool useEscrow,
    uint192 escrowPercentage,
    uint32 escrowDuration,
    uint32 offset
  ) external;

  function changeRewardSpeed(IERC20 rewardToken, uint160 rewardsPerSecond) external;

  function fundReward(IERC20 rewardToken, uint256 amount) external;

  function initialize(
    IERC20 _stakingToken,
    IMultiRewardEscrow _escrow,
    address _owner
  ) external;

  function rewardInfos(IERC20 rewardToken) external view returns (RewardInfo memory);

  function escrowInfos(IERC20 rewardToken) external view returns (EscrowInfo memory);
}