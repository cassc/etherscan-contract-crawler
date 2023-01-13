// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides signature of function for migration
 */
interface IMigrationSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the migration of a contract in a factory
   * @return signature returns signature of the migration function
   */
  function migrationSignature() external view returns (bytes4 signature);
}