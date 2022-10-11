// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

/**
 * @title A preset contract that enables pausable access control.
 * @author Nori Inc.
 * @notice This preset contract affords an inheriting contract a set of standard functionality that allows role-based
 * access control and pausable functions.
 * @dev This contract is inherited by most of the other contracts in this project.
 *
 * ##### Inherits:
 *
 * - [PausableUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable)
 * - [AccessControlEnumerableUpgradeable](
 * https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControlEnumerable)
 */
abstract contract AccessPresetPausable is
  PausableUpgradeable,
  AccessControlEnumerableUpgradeable
{
  /**
   * @notice Role conferring pausing and unpausing of this contract.
   */
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @notice Pauses all functions that can mutate state.
   * @dev Used to effectively freeze a contract so that no state updates can occur.
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE` role.
   */
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * @notice Unpauses all token transfers.
   * @dev Re-enables functionality that was paused by `pause`.
   *
   * ##### Requirements:
   *
   * - The caller must have the `PAUSER_ROLE` role.
   */
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * @notice Grants a role to an account.
   * @dev This function allows the role's admin to grant the role to other accounts.
   *
   * ##### Requirements:
   *
   * - The contract must not be paused.
   *
   * @param role The role to grant.
   * @param account The account to grant the role to.
   */
  function _grantRole(bytes32 role, address account)
    internal
    virtual
    override
    whenNotPaused
  {
    super._grantRole({role: role, account: account});
  }

  /**
   * @notice Revokes a role from an account.
   * @dev This function allows the role's admin to revoke the role from other accounts.
   * ##### Requirements:
   *
   * - The contract must not be paused.
   *
   * @param role The role to revoke.
   * @param account The account to revoke the role from.
   */
  function _revokeRole(bytes32 role, address account)
    internal
    virtual
    override
    whenNotPaused
  {
    super._revokeRole({role: role, account: account});
  }
}