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

import "./AccessControlM.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AuthorityModel is AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  // Platform admin: The role for platform admins. Platform admins can be added. These addresses have privileged
  // access to maintain configuration like the platform fee.
  bytes32 internal constant PLATFORM_ADMIN = keccak256("PLATFORM_ADMIN");

  // Review admin: access to perform reviews of drops, in this case the authority to maintain the drop status parameter, and
  // set it from review to editable (when sending back to the project owner), or from review to approved (when)
  // the drop is ready to go).
  bytes32 internal constant REVIEW_ADMIN = keccak256("REVIEW_ADMIN");

  // Project owner: This is the role for the project itself, i.e. the team that own this drop.
  bytes32 internal constant PROJECT_OWNER = keccak256("PROJECT_OWNER");

  // Address for the factory:
  address internal factory;

  // The super admin can grant and revoke roles
  address public superAdmin;

  // The project owner. Only applicable if inheritor is a Drop or a project.
  address public projectOwner;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _platformAdmins;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _reviewAdmins;

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
  error MustHaveAPlatformAdmin();
  error PlatformAdminCannotBeAddressZero();
  error ReviewAdminCannotBeAddressZero();
  error CannotGrantOrRevokeDirectly();

  /** ====================================================================================================================
   *                                                       MODIFIERS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlySuperAdmin. The associated action can only be taken by the super admin (an address with the
   * default admin role).
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlySuperAdmin() {
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

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformAdmins   Getter for the enumerable list of platform admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformAdmins_  A list of platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformAdmins()
    public
    view
    returns (address[] memory platformAdmins_)
  {
    return (_platformAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getReviewAdmins   Getter for the enumerable list of review admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return reviewAdmins_  A list of review admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getReviewAdmins()
    public
    view
    returns (address[] memory reviewAdmins_)
  {
    return (_reviewAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantPlatformAdmin  Allows the super user Default Admin to add an address to the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_              The address of the new platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantPlatformAdmin(address newPlatformAdmin_) public onlySuperAdmin {
    if (newPlatformAdmin_ == address(0)) {
      revert PlatformAdminCannotBeAddressZero();
    }

    _grantRole(PLATFORM_ADMIN, newPlatformAdmin_);
    // Add this to the enumerated list:
    _platformAdmins.add(newPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantReviewAdmin  Allows the super user Default Admin to add an address to the review admin group.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newReviewAdmin_              The address of the new review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantReviewAdmin(address newReviewAdmin_) public onlySuperAdmin {
    if (newReviewAdmin_ == address(0)) {
      revert ReviewAdminCannotBeAddressZero();
    }
    _grantRole(REVIEW_ADMIN, newReviewAdmin_);
    // Add this to the enumerated list:
    _reviewAdmins.add(newReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokePlatformAdmin  Allows the super user Default Admin to revoke from the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldPlatformAdmin_              The address of the old platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokePlatformAdmin(
    address oldPlatformAdmin_
  ) external onlySuperAdmin {
    _revokeRole(PLATFORM_ADMIN, oldPlatformAdmin_);
    // Remove this from the enumerated list:
    _platformAdmins.remove(oldPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeReviewAdmin  Allows the super user Default Admin to revoke an address to the review admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldReviewAdmin_              The address of the old review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokeReviewAdmin(address oldReviewAdmin_) external onlySuperAdmin {
    _revokeRole(REVIEW_ADMIN, oldReviewAdmin_);
    // Remove this from the enumerated list:
    _reviewAdmins.remove(oldReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferSuperAdmin  Allows the super user Default Admin to transfer this right to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newSuperAdmin_              The address of the new default admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferSuperAdmin(address newSuperAdmin_) external onlySuperAdmin {
    _grantRole(DEFAULT_ADMIN_ROLE, newSuperAdmin_);
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // Update storage of this address:
    superAdmin = newSuperAdmin_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferProjectOwner  Allows the current project owner to transfer this role to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newProjectOwner_   New project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferProjectOwner(
    address newProjectOwner_
  ) external onlyProjectOwner {
    _grantRole(PROJECT_OWNER, newProjectOwner_);
    _revokeRole(PROJECT_OWNER, msg.sender);
    projectOwner = newProjectOwner_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantRole  Override to revert, as all modifications occur through our own functions
   *
   * _____________________________________________________________________________________________________________________
   */
  function grantRole(bytes32, address) public pure override {
    revert CannotGrantOrRevokeDirectly();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeRole  Override to revert, as all modifications occur through our own functions
   *
   * _____________________________________________________________________________________________________________________
   */

  function revokeRole(bytes32, address) public pure override {
    revert CannotGrantOrRevokeDirectly();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) _initialiseAuthorityModel  Set intial authorities and roles
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_        The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_    Array of Platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_      Project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialiseAuthorityModel(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_
  ) internal {
    if (platformAdmins_.length == 0) {
      revert MustHaveAPlatformAdmin();
    }

    // DEFAULT_ADMIN_ROLE can grant and revoke all other roles. This address MUST be secured:
    _grantRole(DEFAULT_ADMIN_ROLE, superAdmin_);
    superAdmin = superAdmin_;

    // Setup the project owner address
    _grantRole(PROJECT_OWNER, projectOwner_);
    projectOwner = projectOwner_;

    // Setup the platform admin addresses
    for (uint256 i = 0; i < platformAdmins_.length; ) {
      _grantRole(PLATFORM_ADMIN, platformAdmins_[i]);
      // Add this to the enumerated list:
      _platformAdmins.add(platformAdmins_[i]);

      unchecked {
        i++;
      }
    }
  }
}