// SPDX-License-Identifier: MIT
// solhint-disable func-name-mixedcase

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IMembershipVault, Position} from "../../../interfaces/IMembershipVault.sol";

import {Context} from "../../../cake/Context.sol";
import {Base} from "../../../cake/Base.sol";
import "../../../cake/Routing.sol" as Routing;

import {ERC721NonTransferable} from "../ERC721NonTransferable.sol";
import {Epochs} from "./Epochs.sol";

import {ERCInterfaces} from "../ERCInterfaces.sol";

using Routing.Context for Context;
using StringsUpgradeable for uint256;

/**
 * @title MembershipVault
 * @notice Track assets held by owners in a vault, as well as the total held in the vault. Assets
 *  are not accounted for until the next epoch for MEV protection.
 * @author Goldfinch
 */
contract MembershipVault is
  IMembershipVault,
  Base,
  ERC721NonTransferable,
  IERC721EnumerableUpgradeable,
  IERC721MetadataUpgradeable,
  Initializable
{
  /// Thrown when depositing from address(0)
  error ZeroAddressInvalid();
  /// Thrown when trying to access tokens from an address with no tokens
  error NoTokensOwned();
  /// Thrown when trying to access more than one token for an address
  error OneTokenPerAddress();
  /// Thrown when querying token supply with an index greater than the supply
  error IndexGreaterThanTokenSupply();
  /// Thrown when checking totals in future epochs
  error NoTotalsInFutureEpochs();
  /// Thrown when adjusting holdings in an unsupported way
  error InvalidHoldingsAdjustment(uint256 eligibleAmount, uint256 nextEpochAmount);
  /// Thrown when requesting a nonexistant token
  error NonexistantToken(uint256 tokenId);

  /**
   * @notice The vault has been checkpointed
   * @param total how much is stored in the vault at the current block.timestamp
   */
  event Checkpoint(uint256 total);

  /// @notice Totals by epoch. totalAmounts is always tracking past epochs, the current
  ///   epoch, and the next epoch. There are a few cases:
  ///   1. Checkpointing
  ///      Noop for the same epoch. Checkpointing occurs before any mutative action
  ///      so for new epochs, the last-set epoch value (totalAmounts[previousEpoch + 1])
  ///      is copied to each epoch up to the current epoch + 1
  ///   2. Increasing
  ///      Checkpointing already occurred, so current epoch and next epoch
  ///      are properly set up. Increasing just updates the next epoch value
  ///   3. Decreasing
  ///      Checkpointing already occurred like above. Decreasing updates the eligible
  ///      and next epoch values
  mapping(uint256 => uint256) private totalAmounts;

  /// @notice last epoch the vault was checkpointed
  uint256 private checkpointEpoch;

  /// @notice all positions held by the vault
  mapping(uint256 => Position) private positions;

  /// @notice owners and their position
  mapping(address => uint256) private owners;

  /// @notice counter tracking most current membership id
  uint256 private membershipIdsTracker;

  /// @notice base uri for the nft
  string public baseURI;

  //solhint-disable-next-line no-empty-blocks
  constructor(Context _context) Base(_context) {}

  function initialize() public initializer {
    checkpointEpoch = Epochs.current();
  }

  //////////////////////////////////////////////////////////////////
  // ERC 721 + Enumerable

  function totalSupply() public view returns (uint256) {
    return membershipIdsTracker;
  }

  function ownerOf(uint256 membershipId) external view returns (address owner) {
    return positions[membershipId].owner;
  }

  function balanceOf(address owner) external view returns (uint256) {
    return owners[owner] > 0 ? 1 : 0;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    uint256 membershipId = owners[owner];
    if (membershipId == 0) revert NoTokensOwned();
    if (index > 0) revert OneTokenPerAddress();

    return membershipId;
  }

  function tokenByIndex(uint256 index) external view returns (uint256) {
    if (index >= totalSupply()) revert IndexGreaterThanTokenSupply();

    return index + 1;
  }

  function supportsInterface(bytes4 id) external pure override returns (bool) {
    return (id == ERCInterfaces.ERC721 ||
      id == ERCInterfaces.ERC721_ENUMERABLE ||
      id == ERCInterfaces.ERC165);
  }

  //////////////////////////////////////////////////////////////////
  // ERC721 Metadata

  /// @inheritdoc IERC721MetadataUpgradeable
  function name() external pure returns (string memory) {
    return "Goldfinch Membership";
  }

  /// @inheritdoc IERC721MetadataUpgradeable
  function symbol() external pure returns (string memory) {
    return "GFMEMBER";
  }

  /// @inheritdoc IERC721MetadataUpgradeable
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    if (tokenId == 0) revert NonexistantToken(tokenId);
    if (tokenId > membershipIdsTracker) revert NonexistantToken(tokenId);

    return string(abi.encodePacked(baseURI, tokenId.toString()));
  }

  /// @notice Set the base uri for the contract
  function setBaseURI(string calldata uri) external onlyAdmin {
    baseURI = uri;
  }

  //////////////////////////////////////////////////////////////////
  // IMembershipVault

  /// @inheritdoc IMembershipVault
  function currentValueOwnedBy(address owner) external view override returns (uint256) {
    Position memory position = positions[owners[owner]];
    if (Epochs.current() > position.checkpointEpoch) {
      return position.nextEpochAmount;
    }

    return position.eligibleAmount;
  }

  /// @inheritdoc IMembershipVault
  function currentTotal() external view override returns (uint256) {
    return totalAtEpoch(Epochs.current());
  }

  /// @inheritdoc IMembershipVault
  function totalAtEpoch(uint256 epoch) public view returns (uint256) {
    if (epoch > Epochs.next()) revert NoTotalsInFutureEpochs();

    if (epoch > checkpointEpoch) {
      // If querying for an epoch past the checkpoint, always use the next amount. This is the amount
      // that will become eligible for every epoch after `checkpointEpoch`.

      return totalAmounts[checkpointEpoch + 1];
    }

    return totalAmounts[epoch];
  }

  /// @inheritdoc IMembershipVault
  function positionOwnedBy(address owner) external view returns (Position memory) {
    return positions[owners[owner]];
  }

  // @inheritdoc IMembershipVault
  function adjustHoldings(
    address owner,
    uint256 eligibleAmount,
    uint256 nextEpochAmount
  ) external onlyOperator(Routing.Keys.MembershipDirector) returns (uint256) {
    if (nextEpochAmount < eligibleAmount)
      revert InvalidHoldingsAdjustment(eligibleAmount, nextEpochAmount);

    uint256 membershipId = _fetchOrCreateMembership(owner);

    _checkpoint(owner);

    Position memory position = positions[membershipId];

    positions[membershipId].eligibleAmount = eligibleAmount;
    positions[membershipId].nextEpochAmount = nextEpochAmount;

    totalAmounts[Epochs.current()] =
      (totalAmounts[Epochs.current()] - position.eligibleAmount) +
      eligibleAmount;
    totalAmounts[Epochs.next()] =
      (totalAmounts[Epochs.next()] - position.nextEpochAmount) +
      nextEpochAmount;

    emit AdjustedHoldings({
      owner: owner,
      eligibleAmount: eligibleAmount,
      nextEpochAmount: nextEpochAmount
    });
    emit VaultTotalUpdate({
      eligibleAmount: totalAmounts[Epochs.current()],
      nextEpochAmount: totalAmounts[Epochs.next()]
    });

    return membershipId;
  }

  // @inheritdoc IMembershipVault
  function checkpoint(address owner) external onlyOperator(Routing.Keys.MembershipDirector) {
    return _checkpoint(owner);
  }

  //////////////////////////////////////////////////////////////////
  // Private

  function _fetchOrCreateMembership(address owner) private returns (uint256) {
    if (owner == address(0)) revert ZeroAddressInvalid();

    uint256 membershipId = owners[owner];
    if (membershipId > 0) return membershipId;

    membershipIdsTracker++;
    membershipId = membershipIdsTracker;

    positions[membershipId].owner = owner;
    positions[membershipId].createdTimestamp = block.timestamp;
    positions[membershipId].checkpointEpoch = Epochs.current();

    owners[owner] = membershipId;

    emit Transfer({from: address(0), to: owner, tokenId: membershipId});

    return membershipId;
  }

  function _checkpoint(address owner) private {
    uint256 currentEpoch = Epochs.current();

    if (currentEpoch > checkpointEpoch) {
      // Promote the last checkpoint's nextAmount to all subsequent epochs up to currentEpoch + 1. This
      // guarantees that total[current] and total[next] are always properly set before any operations
      // are performed.
      uint256 lastCheckpointNextAmount = totalAmounts[checkpointEpoch + 1];
      for (uint256 epoch = checkpointEpoch + 2; epoch <= currentEpoch + 1; epoch++) {
        totalAmounts[epoch] = lastCheckpointNextAmount;
      }

      checkpointEpoch = Epochs.current();
    }

    uint256 membershipId = owners[owner];
    if (membershipId > 0) {
      // positionId of 0 means that no position exists. This occurs if checkpoint is called
      // before a position is created.

      Position memory previousPosition = positions[membershipId];

      // Promote `nextEpochAmount` to `eligibleAmount` if epochs have progressed
      if (currentEpoch > previousPosition.checkpointEpoch) {
        positions[membershipId].eligibleAmount = previousPosition.nextEpochAmount;
        positions[membershipId].checkpointEpoch = Epochs.current();
      }
    }

    emit Checkpoint(totalAmounts[Epochs.current()]);
  }
}