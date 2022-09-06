// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev This module is supposed to be used in Bridge.
///
/// This is adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/access/AccessControl.sol
/// The only difference is added getRoleMemberIndex(bytes32 role, address account) function.

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract BridgeAccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    ///  @notice Emitted when `account` is granted `role`.
    ///
    /// `sender` is the account that originated the contract call, an admin role
    /// bearer except when using {_setupRole}.
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when `account` is revoked `role`.
    ///
    /// `sender` is the account that originated the contract call:
    ///   - if using `revokeRole`, it is the admin role bearer
    ///   - if using `renounceRole`, it is the role bearer (i.e. `account`)
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /// @notice Returns the number of accounts that have `role`. Can be used
    /// together with {getRoleMember} to enumerate all bearers of a role.
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /// @notice Returns one of the accounts that have `role`. `index` must be a
    /// value between 0 and {getRoleMemberCount}, non-inclusive.
    ///
    /// Role bearers are not sorted in any particular way, and their ordering may
    /// change at any point.
    ///
    /// WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
    /// you perform all queries on the same block. See the following
    /// https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
    /// for more information.
    // slither-disable-next-line external-function
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return _roles[role].members.at(index);
    }

    /// @notice Returns the index of the account that have `role`.
    function getRoleMemberIndex(bytes32 role, address account)
        public
        view
        returns (uint256)
    {
        return
            _roles[role].members._inner._indexes[
                bytes32(uint256(uint160(account)))
            ];
    }

    /// @notice Returns the admin role that controls `role`. See {grantRole} and
    /// {revokeRole}.
    ///
    /// To change a role's admin, use {_setRoleAdmin}.
    // slither-disable-next-line external-function
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /// @notice Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    ///
    /// @notice Requirements:
    /// - the caller must have ``role``'s admin role.
    function grantRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

        _grantRole(role, account);
    }

    /// @notice Revokes `role` from `account`.
    ///
    /// If `account` had been granted `role`, emits a {RoleRevoked} event.
    ///
    /// @notice Requirements:
    /// - the caller must have ``role``'s admin role.
    function revokeRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

        _revokeRole(role, account);
    }

    /// @notice Revokes `role` from the calling account.
    ///
    /// Roles are often managed via {grantRole} and {revokeRole}: this function's
    /// purpose is to provide a mechanism for accounts to lose their privileges
    /// if they are compromised (such as when a trusted device is misplaced).
    ///
    /// If the calling account had been granted `role`, emits a {RoleRevoked}
    /// event.
    ///
    /// @notice Requirements:
    /// - the caller must be `account`.
    function renounceRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /// @notice Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event. Note that unlike {grantRole}, this function doesn't perform any
    /// checks on the calling account.
    ///
    /// WARNING: This function should only be called from the constructor when setting
    /// up the initial roles for the system.
    ///
    /// Using this function in any other way is effectively circumventing the admin
    /// system imposed by {AccessControl}.
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /// @notice Sets `adminRole` as ``role``'s admin role.
    // slither-disable-next-line dead-code
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}