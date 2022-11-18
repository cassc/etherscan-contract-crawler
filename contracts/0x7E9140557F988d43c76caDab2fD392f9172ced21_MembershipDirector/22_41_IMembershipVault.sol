// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

struct Position {
  // address owning the position
  address owner;
  // how much of the position is eligible as of checkpointEpoch
  uint256 eligibleAmount;
  // how much of the postion is eligible the epoch after checkpointEpoch
  uint256 nextEpochAmount;
  // when the position was first created
  uint256 createdTimestamp;
  // epoch of the last checkpoint
  uint256 checkpointEpoch;
}

/**
 * @title IMembershipVault
 * @notice Track assets held by owners in a vault, as well as the total held in the vault. Assets
 *  are not accounted for until the next epoch for MEV protection.
 * @author Goldfinch
 */
interface IMembershipVault is IERC721Upgradeable {
  /**
   * @notice Emitted when an owner has adjusted their holdings in a vault
   * @param owner the owner increasing their holdings
   * @param eligibleAmount the new eligible amount
   * @param nextEpochAmount the new next epoch amount
   */
  event AdjustedHoldings(address indexed owner, uint256 eligibleAmount, uint256 nextEpochAmount);

  /**
   * @notice Emitted when the total within the vault has changed
   * @param eligibleAmount new current amount
   * @param nextEpochAmount new next epoch amount
   */
  event VaultTotalUpdate(uint256 eligibleAmount, uint256 nextEpochAmount);

  /**
   * @notice Get the current value of `owner`. This changes depending on the current
   *  block.timestamp as increased holdings are not accounted for until the subsequent epoch.
   * @param owner address owning the positions
   * @return sum of all positions held by an address
   */
  function currentValueOwnedBy(address owner) external view returns (uint256);

  /**
   * @notice Get the total value in the vault as of block.timestamp
   * @return total value in the vault as of block.timestamp
   */
  function currentTotal() external view returns (uint256);

  /**
   * @notice Get the total value in the vault as of epoch
   * @return total value in the vault as of epoch
   */
  function totalAtEpoch(uint256 epoch) external view returns (uint256);

  /**
   * @notice Get the position owned by `owner`
   * @return position owned by `owner`
   */
  function positionOwnedBy(address owner) external view returns (Position memory);

  /**
   * @notice Record an adjustment in holdings. Eligible assets will update this epoch and
   *  total assets will become eligible the subsequent epoch.
   * @param owner the owner to checkpoint
   * @param eligibleAmount amount of points to apply to the current epoch
   * @param nextEpochAmount amount of points to apply to the next epoch
   * @return id of the position
   */
  function adjustHoldings(
    address owner,
    uint256 eligibleAmount,
    uint256 nextEpochAmount
  ) external returns (uint256);

  /**
   * @notice Checkpoint a specific owner & the vault total
   * @param owner the owner to checkpoint
   *
   * @dev to collect rewards, this must be called before `increaseHoldings` or
   *  `decreaseHoldings`. Those functions must call checkpoint internally
   *  so the historical data will be lost otherwise.
   */
  function checkpoint(address owner) external;
}