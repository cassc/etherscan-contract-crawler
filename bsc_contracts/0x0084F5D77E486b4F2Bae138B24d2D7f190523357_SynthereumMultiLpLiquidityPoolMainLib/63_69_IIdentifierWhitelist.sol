// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of identifiers.
 */
interface ISynthereumIdentifierWhitelist {
  /**
   * @notice Adds an identifier to the whitelist.
   * @param newIdentifier the new identifier to add.
   */
  function addToWhitelist(bytes32 newIdentifier) external;

  /**
   * @notice Removes an identifier from the whitelist.
   * @param identifierToRemove The existing identifier to remove.
   */
  function removeFromWhitelist(bytes32 identifierToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param identifierToCheck The address to check.
   * @return True if `identifierToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(bytes32 identifierToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all identifiers that are currently included in the whitelist.
   * @return The list of identifiers on the whitelist.
   */
  function getWhitelist() external view returns (bytes32[] memory);
}