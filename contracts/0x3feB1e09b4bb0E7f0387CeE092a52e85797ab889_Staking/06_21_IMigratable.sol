// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IMigratable {
  /// @notice This event is emitted when a migration target is proposed by the contract owner.
  /// @param migrationTarget Contract address to migrate stakes to.
  event MigrationTargetProposed(address migrationTarget);
  /// @notice This event is emitted after a 7 day period has passed since a migration target is proposed, and the target is accepted.
  /// @param migrationTarget Contract address to migrate stakes to.
  event MigrationTargetAccepted(address migrationTarget);
  /// @notice This event is emitted when a staker migrates their stake to the migration target.
  /// @param staker Staker address
  /// @param principal Principal amount deposited
  /// @param baseReward Amount of base rewards withdrawn
  /// @param delegationReward Amount of delegation rewards withdrawn (if applicable)
  /// @param data Migration payload
  event Migrated(
    address staker,
    uint256 principal,
    uint256 baseReward,
    uint256 delegationReward,
    bytes data
  );

  /// @notice This error is raised when the contract owner supplies a non-contract migration target.
  error InvalidMigrationTarget();

  /// @notice This function returns the migration target contract address
  function getMigrationTarget() external view returns (address);

  /// @notice This function allows the contract owner to set a proposed
  /// migration target address. If the migration target is valid it renounces
  /// the previously accepted migration target (if any).
  /// @param migrationTarget Contract address to migrate stakes to.
  function proposeMigrationTarget(address migrationTarget) external;

  /// @notice This function allows the contract owner to accept a proposed migration target address after a waiting period.
  function acceptMigrationTarget() external;

  /// @notice This function allows stakers to migrate funds to a new staking pool.
  /// @param data Migration path details
  function migrate(bytes calldata data) external;
}