// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title AuthorityModel.sol. Library for global authority components
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

/**
 *
 * @dev Inheritance details:
 *      AccessControl           OZ access control implementation - used for authority control
 *
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AuthorityModel is AccessControl {
  // Platform admin: The role for platform admins. Platform admins can be added. These addresses have privileged
  // access to maintain configuration like the platform fee.
  bytes32 public constant PLATFORM_ADMIN = keccak256("PLATFORM_ADMIN");

  // Review admin: access to perform reviews of drops, in this case the authority to maintain the drop status parameter, and
  // set it from review to editable (when sending back to the project owner), or from review to approved (when)
  // the drop is ready to go).
  bytes32 public constant REVIEW_ADMIN = keccak256("REVIEW_ADMIN");

  // Project owner: This is the role for the project itself, i.e. the team that own this drop.
  bytes32 internal constant PROJECT_OWNER = keccak256("PROJECT_OWNER");

  // Address for the factory:
  address public factory;

  /** ====================================================================================================================
   *                                                        ERRORS
   * =====================================================================================================================
   */
  error CallerIsNotDefaultAdmin(address caller);
  error CallerIsNotPlatformAdmin(address caller);
  error CallerIsNotReviewAdmin(address caller);
  error CallerIsNotPlatformAdminOrProjectOwner(address caller);
  error CallerIsNotPlatformAdminOrFactory(address caller);
  error CallerIsNotProjectOwner(address caller);

  /** ====================================================================================================================
   *                                                       MODIFIERS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyDefaultAdmin. The associated action can only be taken by an address with the
   * default admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyDefaultAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
      revert CallerIsNotDefaultAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdmin() {
    if (!hasRole(PLATFORM_ADMIN, msg.sender))
      revert CallerIsNotPlatformAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyReviewAdmin. The associated action can only be taken by an address with the
   * review admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyReviewAdmin() {
    if (!hasRole(REVIEW_ADMIN, msg.sender))
      revert CallerIsNotReviewAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdminOrProjectOwner. The associated action can only be taken by an address with the
   * platform admin role or project owner role
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdminOrProjectOwner() {
    if (
      !hasRole(PLATFORM_ADMIN, msg.sender) &&
      !hasRole(PROJECT_OWNER, msg.sender)
    ) revert CallerIsNotPlatformAdminOrProjectOwner(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyProjectOwner. The associated action can only be taken by an address with the
   * project owner role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyProjectOwner() {
    if (!hasRole(PROJECT_OWNER, msg.sender))
      revert CallerIsNotProjectOwner(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyFactoryOrPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role or the factory.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyFactoryOrPlatformAdmin() {
    if (msg.sender != factory && !hasRole(PLATFORM_ADMIN, msg.sender))
      revert CallerIsNotPlatformAdminOrFactory(msg.sender);
    _;
  }
}