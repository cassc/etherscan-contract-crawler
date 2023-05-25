// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Basil Gorin
 */
contract AccessControl {
  /**
   * @notice Access manager is responsible for assigning the roles to users,
   *      enabling/disabling global features of the smart contract
   * @notice Access manager can add, remove and update user roles,
   *      remove and update global features
   *
   * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
   * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
   */
  uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

  /**
   * @dev Bitmask representing all the possible permissions (super admin role)
   * @dev Has all the bits are enabled (2^256 - 1 value)
   */
  uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

  /**
   * @notice Privileged addresses with defined roles/permissions
   * @notice In the context of ERC20/ERC721 tokens these can be permissions to
   *      allow minting or burning tokens, transferring on behalf and so on
   *
   * @dev Maps user address to the permissions bitmask (role), where each bit
   *      represents a permission
   * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
   *      represents all possible permissions
   * @dev Zero address mapping represents global features of the smart contract
   */
  mapping(address => uint256) public userRoles;

  /**
   * @dev Fired in updateRole() and updateFeatures()
   *
   * @param _by operator which called the function
   * @param _to address which was granted/revoked permissions
   * @param _requested permissions requested
   * @param _actual permissions effectively set
   */
  event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

  /**
   * @notice Creates an access control instance,
   *      setting contract creator to have full privileges
   */
  constructor() {
    // contract creator has full privileges
    userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
  }

  /**
   * @notice Retrieves globally set of features enabled
   *
   * @dev Auxiliary getter function to maintain compatibility with previous
   *      versions of the Access Control List smart contract, where
   *      features was a separate uint256 public field
   *
   * @return 256-bit bitmask of the features enabled
   */
  function features() public view returns(uint256) {
    // according to new design features are stored in zero address
    // mapping of `userRoles` structure
    return userRoles[address(0)];
  }

  /**
   * @notice Updates set of the globally enabled features (`features`),
   *      taking into account sender's permissions
   *
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   * @dev Function is left for backward compatibility with older versions
   *
   * @param _mask bitmask representing a set of features to enable/disable
   */
  function updateFeatures(uint256 _mask) public {
    // delegate call to `updateRole`
    updateRole(address(0), _mask);
  }

  /**
   * @notice Updates set of permissions (role) for a given user,
   *      taking into account sender's permissions.
   *
   * @dev Setting role to zero is equivalent to removing an all permissions
   * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
   *      copying senders' permissions (role) to the user
   * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
   *
   * @param operator address of a user to alter permissions for or zero
   *      to alter global features of the smart contract
   * @param role bitmask representing a set of permissions to
   *      enable/disable for a user specified
   */
  function updateRole(address operator, uint256 role) public {
    // caller must have a permission to update user roles
    require(isSenderInRole(ROLE_ACCESS_MANAGER), "insufficient privileges (ROLE_ACCESS_MANAGER required)");

    // evaluate the role and reassign it
    userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

    // fire an event
    emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
  }

  /**
   * @notice Determines the permission bitmask an operator can set on the
   *      target permission set
   * @notice Used to calculate the permission bitmask to be set when requested
   *     in `updateRole` and `updateFeatures` functions
   *
   * @dev Calculated based on:
   *      1) operator's own permission set read from userRoles[operator]
   *      2) target permission set - what is already set on the target
   *      3) desired permission set - what do we want set target to
   *
   * @dev Corner cases:
   *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
   *        `desired` bitset is returned regardless of the `target` permission set value
   *        (what operator sets is what they get)
   *      2) Operator with no permissions (zero bitset):
   *        `target` bitset is returned regardless of the `desired` value
   *        (operator has no authority and cannot modify anything)
   *
   * @dev Example:
   *      Consider an operator with the permissions bitmask     00001111
   *      is about to modify the target permission set          01010101
   *      Operator wants to set that permission set to          00110011
   *      Based on their role, an operator has the permissions
   *      to update only lowest 4 bits on the target, meaning that
   *      high 4 bits of the target set in this example is left
   *      unchanged and low 4 bits get changed as desired:      01010011
   *
   * @param operator address of the contract operator which is about to set the permissions
   * @param target input set of permissions to operator is going to modify
   * @param desired desired set of permissions operator would like to set
   * @return resulting set of permissions given operator will set
   */
  function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
    // read operator's permissions
    uint256 p = userRoles[operator];

    // taking into account operator's permissions,
    // 1) enable the permissions desired on the `target`
    target |= p & desired;
    // 2) disable the permissions desired on the `target`
    target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

    // return calculated result
    return target;
  }

  /**
   * @notice Checks if requested set of features is enabled globally on the contract
   *
   * @param required set of features to check against
   * @return true if all the features requested are enabled, false otherwise
   */
  function isFeatureEnabled(uint256 required) public view returns(bool) {
    // delegate call to `__hasRole`, passing `features` property
    return __hasRole(features(), required);
  }

  /**
   * @notice Checks if transaction sender `msg.sender` has all the permissions required
   *
   * @param required set of permissions (role) to check against
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isSenderInRole(uint256 required) public view returns(bool) {
    // delegate call to `isOperatorInRole`, passing transaction sender
    return isOperatorInRole(msg.sender, required);
  }

  /**
   * @notice Checks if operator has all the permissions (role) required
   *
   * @param operator address of the user to check role for
   * @param required set of permissions (role) to check
   * @return true if all the permissions requested are enabled, false otherwise
   */
  function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
    // delegate call to `__hasRole`, passing operator's permissions (role)
    return __hasRole(userRoles[operator], required);
  }

  /**
   * @dev Checks if role `actual` contains all the permissions required `required`
   *
   * @param actual existent role
   * @param required required role
   * @return true if actual has required role (all permissions), false otherwise
   */
  function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
    // check the bitmask for the role required and return the result
    return actual & required == required;
  }
}