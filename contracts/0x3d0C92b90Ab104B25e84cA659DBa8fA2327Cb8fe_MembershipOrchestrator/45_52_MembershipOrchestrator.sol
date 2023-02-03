// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721ReceiverUpgradeable.sol";

import {Base} from "../../cake/Base.sol";
import {PausableUpgradeable} from "../../cake/Pausable.sol";
import {Context} from "../../cake/Context.sol";
import "../../cake/Routing.sol" as Routing;

import {IMembershipDirector} from "../../interfaces/IMembershipDirector.sol";
import "../../interfaces/IMembershipOrchestrator.sol";
import {CapitalAssetType} from "../../interfaces/ICapitalLedger.sol";

import {Epochs} from "./membership/Epochs.sol";
import {MembershipScores} from "./membership/MembershipScores.sol";
import {CapitalAssets} from "./membership/assets/CapitalAssets.sol";

using Routing.Context for Context;
using SafeERC20 for IERC20Upgradeable;

/**
 * @title MembershipOrchestrator
 * @notice Externally facing gateway to all Goldfinch membership functionality.
 * @author Goldfinch
 */
contract MembershipOrchestrator is
  IMembershipOrchestrator,
  Base,
  Initializable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  IERC721ReceiverUpgradeable
{
  /// Thrown when anything is called with an unsupported asset
  error UnsupportedAssetAddress(address addr);
  /// Thrown when calling a method with invalid input
  error RequiresValidInput();
  /// Thrown when operating on an unowned asset
  error CannotOperateOnUnownedAsset(address nonOwner);

  constructor(Context _context) Base(_context) {}

  /// @notice Initialize the contract
  function initialize() external initializer {
    __ReentrancyGuard_init_unchained();
    __Pausable_init_unchained();
  }

  /// @inheritdoc IMembershipOrchestrator
  function deposit(
    Deposit calldata depositData
  ) external nonReentrant whenNotPaused returns (DepositResult memory result) {
    if (depositData.gfi > 0) {
      result.gfiPositionId = _depositGFI(depositData.gfi);
    }

    uint256 numCapitalDeposits = depositData.capitalDeposits.length;

    result.capitalPositionIds = new uint256[](numCapitalDeposits);
    for (uint256 i = 0; i < numCapitalDeposits; i++) {
      CapitalDeposit memory capitalDeposit = depositData.capitalDeposits[i];
      result.capitalPositionIds[i] = _depositCapitalERC721(
        capitalDeposit.assetAddress,
        capitalDeposit.id
      );
    }

    result.membershipId = context.membershipDirector().consumeHoldingsAdjustment(msg.sender);
  }

  /// @inheritdoc IMembershipOrchestrator
  function withdraw(Withdrawal calldata withdrawal) external nonReentrant whenNotPaused {
    // Find the owner that is being withdrawn for. The owner must be the same across all of the
    // positions so the membership vault can be updated.
    address owner = address(0);
    if (withdrawal.gfiPositions.length > 0) {
      owner = context.gfiLedger().ownerOf(withdrawal.gfiPositions[0].id);
    } else if (withdrawal.capitalPositions.length > 0) {
      owner = context.capitalLedger().ownerOf(withdrawal.capitalPositions[0]);
    }

    if (owner == address(0)) revert RequiresValidInput();

    for (uint256 i = 0; i < withdrawal.gfiPositions.length; i++) {
      uint256 positionId = withdrawal.gfiPositions[i].id;
      address positionOwner = context.gfiLedger().ownerOf(positionId);

      if (positionOwner == address(0)) revert CannotOperateOnUnownedAsset(address(0));
      if (positionOwner != owner) revert CannotOperateOnUnownedAsset(positionOwner);

      _withdrawGFI(positionId, withdrawal.gfiPositions[i].amount);
    }

    for (uint256 i = 0; i < withdrawal.capitalPositions.length; i++) {
      uint256 positionId = withdrawal.capitalPositions[i];
      address positionOwner = context.capitalLedger().ownerOf(positionId);

      if (positionOwner == address(0)) revert CannotOperateOnUnownedAsset(address(0));
      if (positionOwner != owner) revert CannotOperateOnUnownedAsset(positionOwner);

      _withdrawCapital(positionId);
    }

    context.membershipDirector().consumeHoldingsAdjustment(owner);
  }

  /// @inheritdoc IMembershipOrchestrator
  function collectRewards() external nonReentrant whenNotPaused returns (uint256) {
    return context.membershipDirector().collectRewards(msg.sender);
  }

  /// @inheritdoc IMembershipOrchestrator
  function harvest(uint256[] calldata capitalPositionIds) external nonReentrant whenNotPaused {
    if (capitalPositionIds.length == 0) revert RequiresValidInput();

    for (uint256 i = 0; i < capitalPositionIds.length; i++) {
      uint256 capitalPositionId = capitalPositionIds[i];

      address owner = context.capitalLedger().ownerOf(capitalPositionId);
      if (owner != msg.sender) revert CannotOperateOnUnownedAsset(msg.sender);

      context.capitalLedger().harvest(capitalPositionId);
    }

    // Consume adjustment to account for possible token principal changes
    // Checkpoints the user's rewards as they may get a new score from the changes
    address owner = context.capitalLedger().ownerOf(capitalPositionIds[0]);
    context.membershipDirector().consumeHoldingsAdjustment(owner);
  }

  /// @inheritdoc IMembershipOrchestrator
  function claimableRewards(address addr) external view returns (uint256) {
    return context.membershipDirector().claimableRewards(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function votingPower(address addr) external view returns (uint256) {
    (, uint256 total) = context.gfiLedger().totalsOf(addr);
    return total;
  }

  /// @inheritdoc IMembershipOrchestrator
  function totalGFIHeldBy(
    address addr
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount) {
    return context.gfiLedger().totalsOf(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function totalCapitalHeldBy(
    address addr
  ) external view returns (uint256 eligibleAmount, uint256 totalAmount) {
    return context.capitalLedger().totalsOf(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function memberScoreOf(
    address addr
  ) external view returns (uint256 eligibleScore, uint256 totalScore) {
    return context.membershipDirector().currentScore(addr);
  }

  /// @inheritdoc IMembershipOrchestrator
  function estimateRewardsFor(uint256 epoch) external view returns (uint256) {
    return context.membershipCollector().estimateRewardsFor(epoch);
  }

  /// @inheritdoc IMembershipOrchestrator
  function calculateMemberScore(uint256 gfi, uint256 capital) external view returns (uint256) {
    return context.membershipDirector().calculateMembershipScore(gfi, capital);
  }

  function finalizeEpochs() external nonReentrant whenNotPaused {
    return context.membershipDirector().finalizeEpochs();
  }

  /// @inheritdoc IMembershipOrchestrator
  function estimateMemberScore(
    address memberAddress,
    int256 gfi,
    int256 capital
  ) external view returns (uint256 score) {
    return context.membershipDirector().estimateMemberScore(memberAddress, gfi, capital);
  }

  /// @inheritdoc IMembershipOrchestrator
  function totalMemberScores()
    external
    view
    returns (uint256 eligibleTotal, uint256 nextEpochTotal)
  {
    return context.membershipDirector().totalMemberScores();
  }

  /// @inheritdoc IERC721ReceiverUpgradeable
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _depositGFI(uint256 amount) private returns (uint256) {
    uint256 balanceBefore = context.gfi().balanceOf(address(this));

    context.gfi().safeTransferFrom(msg.sender, address(this), amount);

    context.gfi().approve(address(context.gfiLedger()), amount);
    uint256 positionId = context.gfiLedger().deposit(msg.sender, amount);

    assert(context.gfi().balanceOf(address(this)) == balanceBefore);

    return positionId;
  }

  function _depositCapitalERC721(address assetAddress, uint256 id) private returns (uint256) {
    if (CapitalAssets.getSupportedType(context, assetAddress) == CapitalAssetType.INVALID) {
      revert UnsupportedAssetAddress(assetAddress);
    }

    IERC721Upgradeable asset = IERC721Upgradeable(assetAddress);

    asset.safeTransferFrom(msg.sender, address(this), id);

    asset.approve(address(context.capitalLedger()), id);
    uint256 positionId = context.capitalLedger().depositERC721(msg.sender, assetAddress, id);

    assert(asset.ownerOf(id) != address(this));

    return positionId;
  }

  function _withdrawGFI(uint256 positionId) private returns (uint256) {
    if (context.gfiLedger().ownerOf(positionId) != msg.sender) {
      revert CannotOperateOnUnownedAsset(msg.sender);
    }

    return context.gfiLedger().withdraw(positionId);
  }

  function _withdrawGFI(uint256 positionId, uint256 amount) private returns (uint256) {
    if (context.gfiLedger().ownerOf(positionId) != msg.sender) {
      revert CannotOperateOnUnownedAsset(msg.sender);
    }

    return context.gfiLedger().withdraw(positionId, amount);
  }

  function _withdrawCapital(uint256 positionId) private {
    if (context.capitalLedger().ownerOf(positionId) != msg.sender) {
      revert CannotOperateOnUnownedAsset(msg.sender);
    }

    context.capitalLedger().withdraw(positionId);
  }
}