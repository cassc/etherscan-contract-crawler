// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Base} from "../../../cake/Base.sol";
import {Context} from "../../../cake/Context.sol";
import "../../../cake/Routing.sol" as Routing;

import "../../../interfaces/IMembershipDirector.sol";
import {IMembershipVault, Position} from "../../../interfaces/IMembershipVault.sol";

import {MembershipScores} from "./MembershipScores.sol";
import {CapitalAssets} from "./assets/CapitalAssets.sol";
import {Epochs} from "./Epochs.sol";

using Routing.Context for Context;

contract MembershipDirector is IMembershipDirector, Base, Initializable {
  error InvalidVaultPosition();
  error InvalidPositionType();

  /// @notice Emitted when `owner` claims fidu `rewards`
  /// @param owner the owner claiming rewards
  /// @param rewards amount of fidu claimed
  event RewardsClaimed(address indexed owner, uint256 rewards);

  constructor(Context _context) Base(_context) {}

  /// @inheritdoc IMembershipDirector
  function consumeHoldingsAdjustment(address owner)
    external
    onlyOperator(Routing.Keys.MembershipOrchestrator)
    returns (uint256)
  {
    _allocateRewards(owner);

    (uint256 eligibleGFI, uint256 totalGFI) = context.gfiLedger().totalsOf(owner);
    (uint256 eligibleCapital, uint256 totalCapital) = context.capitalLedger().totalsOf(owner);

    return
      context.membershipVault().adjustHoldings({
        owner: owner,
        eligibleAmount: calculateMembershipScore({gfi: eligibleGFI, capital: eligibleCapital}),
        nextEpochAmount: calculateMembershipScore({gfi: totalGFI, capital: totalCapital})
      });
  }

  /// @inheritdoc IMembershipDirector
  function collectRewards(address owner)
    external
    onlyOperator(Routing.Keys.MembershipOrchestrator)
    returns (uint256 rewards)
  {
    rewards = _allocateRewards(owner);

    context.membershipLedger().resetRewards(owner);

    context.membershipCollector().distributeFiduTo(owner, rewards);

    emit RewardsClaimed(owner, rewards);
  }

  /// @inheritdoc IMembershipDirector
  function claimableRewards(address owner) external view returns (uint256) {
    uint256 allocatedRewards = context.membershipLedger().getPendingRewardsFor(owner);

    Position memory position = context.membershipVault().positionOwnedBy(owner);
    uint256 rewardsToLastFinalizedEpoch = _calculateRewards(
      position.checkpointEpoch,
      position.eligibleAmount,
      position.nextEpochAmount
    );

    /// @dev if an epoch has passed, but is not finalized, those rewards are not counted
    ///  although they would be claimed if collectRewards were called.

    return allocatedRewards + rewardsToLastFinalizedEpoch;
  }

  /// @inheritdoc IMembershipDirector
  function currentScore(address owner) external view returns (uint256 eligibleScore, uint256 totalScore) {
    Position memory position = context.membershipVault().positionOwnedBy(owner);
    return (position.eligibleAmount, position.nextEpochAmount);
  }

  /// @inheritdoc IMembershipDirector
  function calculateMembershipScore(uint256 gfi, uint256 capital) public view returns (uint256) {
    (uint256 alphaNumerator, uint256 alphaDenominator) = context.membershipLedger().alpha();

    return
      MembershipScores.calculateScore({
        gfi: gfi,
        capital: capital,
        alphaNumerator: alphaNumerator,
        alphaDenominator: alphaDenominator
      });
  }

  /// @inheritdoc IMembershipDirector
  function totalMemberScores() external view returns (uint256 eligibleTotal, uint256 nextEpochTotal) {
    return (
      context.membershipVault().totalAtEpoch(Epochs.current()),
      context.membershipVault().totalAtEpoch(Epochs.next())
    );
  }

  /// @inheritdoc IMembershipDirector
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score) {
    (uint256 alphaNumerator, uint256 alphaDenominator) = context.membershipLedger().alpha();

    (, uint256 totalGFI) = context.gfiLedger().totalsOf(memberAddress);
    (, uint256 totalCapital) = context.capitalLedger().totalsOf(memberAddress);

    uint256 resultingGFI = totalGFI;
    if (gfi < 0) resultingGFI -= uint256(-gfi);
    else resultingGFI += uint256(gfi);

    uint256 resultingCapital = totalCapital;
    if (capital < 0) resultingCapital -= uint256(-capital);
    else resultingCapital += uint256(capital);

    return
      MembershipScores.calculateScore({
        gfi: resultingGFI,
        capital: resultingCapital,
        alphaNumerator: alphaNumerator,
        alphaDenominator: alphaDenominator
      });
  }

  /// @inheritdoc IMembershipDirector
  function finalizeEpochs() external onlyOperator(Routing.Keys.MembershipOrchestrator) {
    context.membershipCollector().finalizeEpochs();
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _allocateRewards(address owner) private returns (uint256) {
    if (context.membershipCollector().lastFinalizedEpoch() < Epochs.current() - 1) {
      // Guarantee that lastFinalizedEpoch is always up to date when distributing rewards
      // Without this, we will never distribute rewards for an epoch that has already
      // passed but is not finalized: the vault's checkpoint will update to epochs.current()
      // so we will never attempt the missing epoch again.

      context.membershipCollector().finalizeEpochs();
    }

    Position memory position = context.membershipVault().positionOwnedBy(owner);

    context.membershipVault().checkpoint(owner);

    uint256 rewards = _calculateRewards(position.checkpointEpoch, position.eligibleAmount, position.nextEpochAmount);

    return context.membershipLedger().allocateRewardsTo(owner, rewards);
  }

  function _calculateRewards(
    uint256 startEpoch,
    uint256 eligibleMemberScore,
    uint256 nextEpochMemberScore
  ) private view returns (uint256 rewards) {
    if (eligibleMemberScore > 0) {
      if (startEpoch < Epochs.current()) {
        rewards += _shareOfEpochRewards(startEpoch, eligibleMemberScore);
      }
    }

    if (nextEpochMemberScore > 0) {
      for (uint256 epoch = startEpoch + 1; epoch < Epochs.current(); epoch++) {
        rewards += _shareOfEpochRewards(epoch, nextEpochMemberScore);
      }
    }
  }

  function _shareOfEpochRewards(uint256 epoch, uint256 memberScore) private view returns (uint256) {
    uint256 totalMemberScores = context.membershipVault().totalAtEpoch(epoch);
    uint256 rewardTotal = context.membershipCollector().rewardsForEpoch(epoch);

    if (memberScore > totalMemberScores) revert InvalidVaultPosition();
    if (totalMemberScores == 0) return 0;

    return (memberScore * rewardTotal) / totalMemberScores;
  }
}