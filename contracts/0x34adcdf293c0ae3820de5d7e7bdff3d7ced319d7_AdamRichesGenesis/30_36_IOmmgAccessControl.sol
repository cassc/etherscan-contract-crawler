// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgAccessControl
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for a lightweight custom implementation of role based permissions.
interface IOmmgAccessControl {
    struct RoleData {
        mapping(address => bool) members;
    }

    /// @notice Triggers when an unauthorized address attempts
    /// a restricted action
    /// @param account initiated the unauthorized action
    /// @param missingRole the missing role identifier
    error Unauthorized(address account, bytes32 missingRole);

    /// @notice Emitted when `account` is granted `role`
    /// @param role the role granted
    /// @param account the account that is granted `role`
    /// @param sender the address that initiated this action
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when `account` is revoked `role`
    /// @param role the role revoked
    /// @param account the account that is revoked `role`
    /// @param sender the address that initiated this action
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Returns `true` if `account` has been granted `role`.
    /// @param role the role identifier
    /// @param account the account to check
    /// @return hasRole whether `account` has `role` or not.
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool hasRole);

    /// @notice Grants `role` to `account`. Emits {RoleGranted}.
    /// @param role the role identifier
    /// @param account the account to grant `role` to
    function grantRole(bytes32 role, address account) external;

    /// @notice Grants `role` to `account`. Emits {RoleRevoked}.
    /// @param role the role identifier
    /// @param account the account to revoke `role` from
    function revokeRole(bytes32 role, address account) external;

    /// @notice Rennounces `role` from the calling account. Emits {RoleRevoked}.
    /// @param role the role identifier of the role to rennounce
    function renounceRole(bytes32 role) external;
}