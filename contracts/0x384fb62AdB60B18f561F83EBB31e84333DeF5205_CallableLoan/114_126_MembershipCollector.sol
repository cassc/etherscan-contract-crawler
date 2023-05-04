// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {Context} from "../../../cake/Context.sol";
import {Base} from "../../../cake/Base.sol";
import "../../../cake/Routing.sol" as Routing;

import {IERC20SplitterReceiver} from "./ERC20Splitter.sol";
import {ISeniorPool} from "../../../interfaces/ISeniorPool.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";
import {IMembershipCollector} from "../../../interfaces/IMembershipCollector.sol";

import {Epochs} from "./Epochs.sol";

using Routing.Context for Context;
using SafeERC20 for IERC20Upgradeable;

/// @title MembershipCollector
/// @author landakram
/// @notice Responsible for receiving USDC from ERC20Splitter, using it to acquire fidu, and allocating
///   it to epochs, where it can be claimed by membership participants.
contract MembershipCollector is IERC20SplitterReceiver, IMembershipCollector, Base {
  error InvalidReceiveCaller();

  /// @notice Emitted once `epoch` has been finalized and will no longer change
  /// @param epoch epoch that is now finalized
  /// @param totalRewards all of the rewards in that epoch
  event EpochFinalized(uint256 indexed epoch, uint256 totalRewards);

  /// @notice The last block.timestamp when epochs were finalized. The last
  ///   finalized epoch is the most recent epoch that ends before lastCheckpointAt.
  uint256 public lastCheckpointAt;

  /// @notice A mapping of epochs to fidu reward amounts
  mapping(uint256 => uint256) public rewardsForEpoch;

  /// @notice The first epoch rewards should be provided in
  uint256 public immutable firstRewardEpoch;

  constructor(Context _context, uint256 _firstRewardEpoch) Base(_context) {
    firstRewardEpoch = _firstRewardEpoch;
  }

  /// @notice Receive handler for the reserve ERC20Splitter. This handler uses the USDC
  ///   amount it has received to acquire fidu from the senior pool and distribute it across
  ///   epochs that have elapsed since the last distribution. The fidu rewards are distributed
  ///   proportionaly across epochs based on their portion of total elapsed time. Once an epoch
  ///   has passed, it is consider "finalized" and no longer considered for future runs of this
  ///   function.
  /// @param amount USDC reward amount
  /// @return The 4 byte selector required by IERC20SplitterReceiver
  function onReceive(uint256 amount) external returns (bytes4) {
    if (msg.sender != address(context.reserveSplitter())) revert InvalidReceiveCaller();

    // Acquire fidu
    uint256 fiduAmount = 0;
    if (amount > 0) {
      ISeniorPool seniorPool = context.seniorPool();
      context.usdc().approve(address(seniorPool), amount);
      fiduAmount = seniorPool.deposit(amount);
    }

    // Distribute fidu amount to epochs which have passed since last distribution
    allocateToElapsedEpochs(fiduAmount);

    return IERC20SplitterReceiver.onReceive.selector;
  }

  function finalizeEpochs() external onlyOperator(Routing.Keys.MembershipDirector) {
    if (context.reserveSplitter().lastDistributionAt() == block.timestamp) return;

    context.reserveSplitter().distribute();

    // splitter will then callback to allocateToElapsedEpochs and epochs will be finalized
  }

  function estimateRewardsFor(uint256 epoch) external view returns (uint256) {
    /// @dev epochs fall into 6 different cases:
    ///
    ///                   ┌ first reward epoch    ┌ last finalized                    ┌ current
    ///                   |                       |                                   |
    /// |  epoch a  |  epoch a  |  epoch b  |  epoch c  |  epoch d  |  epoch e  |  epoch f  |  epoch g  |
    /// |  case 2   |               case 3              |         case 6        |  case 4&5 |   case 1  |

    // Case 1: Epoch is in the future
    if (epoch > Epochs.current()) return 0;

    // Case 2: Before first reward epoch
    if (epoch < firstRewardEpoch) return 0;

    // Case 3: Epoch has already been finalized
    uint256 _lastFinalizedEpoch = lastFinalizedEpoch();
    if (epoch <= _lastFinalizedEpoch) return rewardsForEpoch[epoch];

    uint256 pendingDistributionUsdc = context.reserveSplitter().pendingDistributionFor(
      address(this)
    );
    uint256 pendingDistribution = context.seniorPool().getNumShares(pendingDistributionUsdc);

    uint256 epochsToFinalize = Epochs.previous() - _lastFinalizedEpoch;
    if (epochsToFinalize == 0) {
      // Case 4: Epoch is the current epoch and there are none pending finalization
      // Epoch is implicitly current: it's not the future and all previous are finalized
      return rewardsForEpoch[epoch] + pendingDistribution;
    }

    uint256 checkpointEpoch = Epochs.fromSeconds(lastCheckpointAt);

    uint256 checkpointEpochStart = Epochs.startOf(checkpointEpoch);
    uint256 secondsAlreadyCheckpointed = 0;
    if (lastCheckpointAt > checkpointEpochStart) {
      secondsAlreadyCheckpointed = lastCheckpointAt - checkpointEpochStart;
    }
    uint256 durationToFinalize = epochsToFinalize *
      Epochs.EPOCH_SECONDS -
      secondsAlreadyCheckpointed;

    uint256 currentEpochElapsedTime = block.timestamp - Epochs.currentEpochStartTimestamp();
    if (epoch == Epochs.current()) {
      uint256 currentEpochPendingRewards = (pendingDistribution * currentEpochElapsedTime) /
        (durationToFinalize + currentEpochElapsedTime);

      // Case 5: Epoch is the current epoch but there are some pending finalization
      return rewardsForEpoch[epoch] + currentEpochPendingRewards;
    }

    // Case 6: Epoch is pending finalization
    // If we're in the checkpoint epoch, account for seconds already checkpointed
    uint256 unfinalizedEpochSeconds = Epochs.EPOCH_SECONDS;
    if (epoch == checkpointEpoch) {
      unfinalizedEpochSeconds = Epochs.EPOCH_SECONDS - secondsAlreadyCheckpointed;
    }

    uint256 epochPendingRewards = (pendingDistribution * unfinalizedEpochSeconds) /
      (durationToFinalize + currentEpochElapsedTime);

    return rewardsForEpoch[epoch] + epochPendingRewards;
  }

  /// @inheritdoc IMembershipCollector
  function distributeFiduTo(
    address addr,
    uint256 amount
  ) external onlyOperator(Routing.Keys.MembershipDirector) {
    context.fidu().safeTransfer(addr, amount);
  }

  function allocateToElapsedEpochs(uint256 fiduAmount) internal {
    uint256 rewardsRemaining = fiduAmount;

    // Calculate epochs to finalize ([current() - 1] - lastFinalizedEpoch);
    uint256 currentEpoch = Epochs.current();
    uint256 priorEpoch = currentEpoch - 1;

    // If running before the first reward epoch, allocate rewards to that epoch
    if (currentEpoch < firstRewardEpoch) {
      rewardsForEpoch[firstRewardEpoch] += rewardsRemaining;

      if (lastCheckpointAt == 0) {
        // Consider all earlier epochs finalized
        lastCheckpointAt = Epochs.startOf(firstRewardEpoch);
        emit EpochFinalized({epoch: firstRewardEpoch - 1, totalRewards: 0});
      }

      return;
    }

    // If running this function for the first time, distribute everything to the current
    // epoch, and consider all prior epochs finalized.
    if (lastCheckpointAt == 0) {
      lastCheckpointAt = Epochs.startOf(currentEpoch);
    }

    uint256 _lastFinalizedEpoch = lastFinalizedEpoch();
    uint256 epochsToFinalize = priorEpoch - _lastFinalizedEpoch;

    // Distribute rewards to epochsToFinalize according to proportion of total elapsed time
    uint256 totalElapsedTime = block.timestamp - lastCheckpointAt;

    uint256 finalizedEpochRewards = 0;

    if (epochsToFinalize > 0) {
      for (uint256 i = 1; i <= epochsToFinalize; i++) {
        uint256 epoch = _lastFinalizedEpoch + i;

        uint256 epochStart = Epochs.startOf(epoch);
        uint256 unfinalizedEpochSeconds = Epochs.EPOCH_SECONDS;
        // If the epoch was checkpointed partway through, use the elapsed time since the last checkpoint
        if (epochStart < lastCheckpointAt) {
          uint256 secondsAlreadyCheckpointed = lastCheckpointAt - epochStart;
          unfinalizedEpochSeconds = Epochs.EPOCH_SECONDS - secondsAlreadyCheckpointed;
        }

        uint256 epochRewards = (fiduAmount * unfinalizedEpochSeconds) / totalElapsedTime;

        rewardsForEpoch[epoch] += epochRewards;
        finalizedEpochRewards += epochRewards;

        emit EpochFinalized({epoch: epoch, totalRewards: rewardsForEpoch[epoch]});
      }

      rewardsRemaining -= finalizedEpochRewards;
    }

    // Distribute remainder of rewards to current epoch
    rewardsForEpoch[currentEpoch] += rewardsRemaining;

    // Checkpoint
    lastCheckpointAt = block.timestamp;
  }

  /// @notice The last epoch whose rewards should be considered finalized and ready to be claimed
  function lastFinalizedEpoch() public view returns (uint256) {
    if (lastCheckpointAt < Epochs.EPOCH_SECONDS) return 0;
    return Epochs.fromSeconds(lastCheckpointAt) - 1;
  }
}