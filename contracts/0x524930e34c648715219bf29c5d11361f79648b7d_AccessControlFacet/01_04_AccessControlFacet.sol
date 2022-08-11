// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {AccessControl} from "../libraries/LibAccessControl.sol";

/// @title AccessControlFacet
/// @author Kfish n Chips
/// @notice Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
/// @dev Contract facet that implement role-based access
/// control mechanisms. This is a lightweight version that doesn't allow enumerating role
/// members except through off-chain means by accessing the contract event logs. Some
/// applications may benefit from on-chain enumerability, for those cases see
/// {AccessControlEnumerable}.
///
/// Roles are referred to by their `bytes32` identifier. These should be exposed
/// in the external API and be unique. The best way to achieve this is by
/// using `public constant` hash digests:
///
/// ```
/// bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
/// ```
///
/// Roles can be used to represent a set of permissions. To restrict access to a
/// function call, use add the access at the facet setup:
///
/// ```
/// selectors[1] = FunctionSelector(
///     RoyaltyFacet.setTokenRoyalty.selector,
///     adminAccess()
/// );
/// ```
///
/// Roles can be granted and revoked dynamically via the {grantRole} and
/// {revokeRole} functions. Each role has an associated admin role, and only
/// accounts that have a role's admin role can call {grantRole} and {revokeRole}.
///
/// ```
/// accessControlFacet.grantRole(
///           AccessControl.DEFAULT_ADMIN_ROLE,
///           DEFAULT_ADMIN
/// );
/// ```
///
/// By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
/// that only accounts with this role will be able to grant or revoke other
/// roles. More complex role relationships can be created by using
/// {_setRoleAdmin}.
///
/// WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
/// grant and revoke this role. Extra precautions should be taken to secure
/// accounts that have been granted it..
///
/// @custom:security-contact [email protected]
contract AccessControlFacet {

    /// @notice Grants `role` to `member`.
    /// @dev the caller must have ``role``'s admin role.
    /// @param role Roles are referred to by their `bytes32` identifier.
    /// @param member If `member` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    function grantRole(bytes32 role, address member) external {
        AccessControl.grantRole(role, member);
    }


    /// @notice Revokes `role` from `account`.
    /// @dev the caller must have ``role``'s admin role.
    /// @param role the `bytes32` identifier of the role.
    /// @param member If `account` had been granted `role`, emits a {RoleRevoked} event.
    function revokeRole(bytes32 role, address member) external {
        AccessControl.revokeRole(role, member);
    }

    /// @notice Revokes `role` from the calling account.
    /// @dev Roles are often managed via {grantRole} and {revokeRole}: this function's
    /// purpose is to provide a mechanism for accounts to lose their privileges
    /// if they are compromised (such as when a trusted device is misplaced).
    /// @param role the `bytes32` identifier of the role.
    /// @param member the caller must be `account`, emits a {RoleRevoked} event.
    function renounceRole(bytes32 role, address member) external {
        AccessControl. renounceRole( role,  member);
    }


    /// @notice Check that account has role
    /// @param role a role referred to by their `bytes32` identifier.
    /// @param member the account to check
    /// @return  Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address member) external view returns (bool) {
        return AccessControl.hasRole(role, member);
    }

    
    
}