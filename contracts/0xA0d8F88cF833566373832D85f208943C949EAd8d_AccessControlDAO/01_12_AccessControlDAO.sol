//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IAccessControlDAO.sol";

/// @title Access Control
/// @notice Use this contract for managing DAO role based permissions
contract AccessControlDAO is IAccessControlDAO, ERC165, UUPSUpgradeable {
    string public constant DAO_ROLE = "DAO_ROLE";
    string public constant OPEN_ROLE = "OPEN_ROLE";

    mapping(string => RoleData) private _roles;
    mapping(address => mapping(bytes4 => string[])) private _actionsToRoles;

    /// @notice Modifier that checks that an account has a specific role. Reverts
    /// with a standardized message including the required role.
    modifier onlyRole(string memory role) {
        _checkRole(role, msg.sender);
        _;
    }

    /// @notice Initialize DAO action and role permissions
    /// @param dao Address to receive DAO role
    /// @param roles What permissions are assigned to
    /// @param roleAdmins Roles which have the ability to remove or add members
    /// @param members Addresses to be granted the specified roles
    /// @param targets Contract addresses for actions to be defined on
    /// @param functionDescs Function descriptions used to define actions
    /// @param actionRoles Roles being granted permission for an action
    function initialize(
        address dao,
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members,
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory actionRoles
    ) external initializer {
        if (
            roles.length != roleAdmins.length ||
            roles.length != members.length ||
            targets.length != functionDescs.length ||
            targets.length != functionDescs.length
        ) revert UnequalArrayLengths();

        _grantRole(DAO_ROLE, dao);
        _grantRolesAndAdmins(roles, roleAdmins, members);
        _addActionsRoles(targets, functionDescs, actionRoles);
        __UUPSUpgradeable_init();
    }

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param roleAdmins The roles being granted as admins of the specified of roles
    /// @param members Addresses being granted each specified role
    function grantRolesAndAdmins(
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members
    ) external onlyRole(DAO_ROLE) {
        _grantRolesAndAdmins(roles, roleAdmins, members);
    }

    /// @notice Grants roles to the specified addresses
    /// @param roles The roles being granted
    /// @param members Addresses being granted each specified role
    function grantRoles(string[] memory roles, address[][] memory members)
        external
        onlyRole(DAO_ROLE)
    {
        _grantRoles(roles, members);
    }

    /// @notice Grants a role to the specified address
    /// @param role The role being granted
    /// @param account The address being granted the specified role
    function grantRole(string memory role, address account)
        external
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /// @notice Revokes a role from the specified address
    /// @param role The role being revoked
    /// @param account The address the role is being revoked from
    function revokeRole(string memory role, address account)
        external
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /// @notice Enables an address to remove one of its own roles
    /// @param role The role being renounced
    /// @param account The address renouncing the role
    function renounceRole(string memory role, address account) external {
        if (account != msg.sender) {
            revert OnlySelfRenounce();
        }

        _revokeRole(role, account);
    }

    /// @notice Authorizes roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function descriptions used to define the actions
    /// @param roles Roles being granted permission for an action
    function addActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) external onlyRole(DAO_ROLE) {
        _addActionsRoles(targets, functionDescs, roles);
    }

    /// @notice Removes autorization for roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function description used to define the actions
    /// @param roles Roles that action permissions are being removed on
    function removeActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) external onlyRole(DAO_ROLE) {
        if (targets.length != functionDescs.length)
            revert UnequalArrayLengths();
        if (targets.length != roles.length) revert UnequalArrayLengths();
        uint256 actionsLength = targets.length;
        for (uint256 i = 0; i < actionsLength; ) {
            uint256 rolesLength = roles[i].length;
            for (uint256 j = 0; j < rolesLength; ) {
                _removeActionRole(targets[i], functionDescs[i], roles[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if a caller has the permissions to execute the specific action
    /// @param caller Address attempting to execute the action
    /// @param target Contract address corresponding to the action
    /// @param sig The function signature used to define the action
    function actionIsAuthorized(
        address caller,
        address target,
        bytes4 sig
    ) external view returns (bool isAuthorized) {
        string[] memory roles = _actionsToRoles[target][sig];
        uint256 roleLength = roles.length;

        for (uint256 i = 0; i < roleLength; ) {
            if (hasRole(roles[i], caller)) {
                isAuthorized = true;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Returns the roles autorized to execute the specified action
    /// @param target Contract address corresponding to the action
    /// @param functionDesc The function description used to define the action
    function getActionRoles(address target, string memory functionDesc)
        external
        view
        returns (string[] memory roles)
    {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        return _actionsToRoles[target][encodedSig];
    }

    /// @notice Checks if a specific role is authorized for an action
    /// @param role Role that authorization is being checked on
    /// @param target Contract address corresponding to the action
    /// @param functionDesc Function description used to define the action
    /// @return isAuthorized Indicates whether the role is authorized to execute the action
    function isRoleAuthorized(
        string calldata role,
        address target,
        string memory functionDesc
    ) external view returns (bool isAuthorized) {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        string[] memory roles = _actionsToRoles[target][encodedSig];
        uint256 rolesLength = roles.length;

        for (uint256 i = 0; i < rolesLength; ) {
            if (
                keccak256(abi.encodePacked(role)) ==
                keccak256(abi.encodePacked(roles[i]))
            ) {
                isAuthorized = true;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Returns whether the account has been granted the role
    /// @param role Role that authorization is being checked on
    /// @param account Address that the role authorization is being check on
    /// @return boolean Indicates whether the address has been granted the role
    function hasRole(string memory role, address account)
        public
        view
        returns (bool)
    {
        if (
            keccak256(bytes(role)) ==
            keccak256(bytes(OPEN_ROLE))
        ) {
            return true;
        } else {
            return _roles[role].members[account];
        }
    }

    /// @notice Returns the role that is the admin of the specified role
    /// @param role Role that the admin role is being returned for
    /// @return string The admin role of the specified role
    function getRoleAdmin(string memory role)
        public
        view
        returns (string memory)
    {
        return _roles[role].adminRole;
    }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlDAO).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Sets a role as the admin of another role
    /// @param role The role the admin is being set for
    /// @param adminRole The role that is being assigned as an admin
    function _setRoleAdmin(string memory role, string memory adminRole)
        internal
    {
        string memory previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @notice Grants a role to the specified address
    /// @param role The role being granted
    /// @param account The address being granted the specified role
    function _grantRole(string memory role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /// @notice Revokes a role from the specified address
    /// @param role The role being revoked
    /// @param account The address the role is being revoked from
    function _revokeRole(string memory role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param roleAdmins The roles being granted as admins of the specified of roles
    /// @param members Addresses being granted each specified role
    function _grantRolesAndAdmins(
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members
    ) internal {
        if (roles.length != roleAdmins.length) revert UnequalArrayLengths();
        if (roles.length != members.length) revert UnequalArrayLengths();

        uint256 rolesLength = roles.length;
        for (uint256 i = 0; i < rolesLength; ) {
            _setRoleAdmin(roles[i], roleAdmins[i]);

            uint256 membersLength = members[i].length;
            for (uint256 j = 0; j < membersLength; ) {
                _grantRole(roles[i], members[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param members Addresses being granted each specified role
    function _grantRoles(string[] memory roles, address[][] memory members)
        internal
    {
        if (roles.length != members.length) revert UnequalArrayLengths();

        uint256 rolesLength = roles.length;
        for (uint256 i = 0; i < rolesLength; ) {
            uint256 membersLength = members[i].length;
            for (uint256 j = 0; j < membersLength; ) {
                _grantRole(roles[i], members[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Authorizes roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function descriptions used to define the actions
    /// @param roles Roles being granted permission for an action
    function _addActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) internal {
        if (targets.length != functionDescs.length)
            revert UnequalArrayLengths();
        if (targets.length != roles.length) revert UnequalArrayLengths();

        uint256 targetsLength = targets.length;
        for (uint256 i = 0; i < targetsLength; ) {
            uint256 rolesLength = roles[i].length;
            for (uint256 j = 0; j < rolesLength; ) {
                _addActionRole(targets[i], functionDescs[i], roles[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Authorizes a role to execute the specified action
    /// @param target The contract address that the action function is implemented on
    /// @param functionDesc The function description used to define the action
    /// @param role Role being granted permission for an action
    function _addActionRole(
        address target,
        string memory functionDesc,
        string memory role
    ) internal {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        _actionsToRoles[target][encodedSig].push(role);

        emit ActionRoleAdded(target, functionDesc, encodedSig, role);
    }

    /// @notice Removes authorization of a role to execute the specified action
    /// @param target The contract address that the action function is implemented on
    /// @param functionDesc The function description used to define the action
    /// @param role Role that the action authorization is being removed on
    function _removeActionRole(
        address target,
        string memory functionDesc,
        string memory role
    ) internal {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        uint256 rolesLength = _actionsToRoles[target][encodedSig].length;
        for (uint256 i = 0; i < rolesLength; ) {
            if (
                keccak256(
                    abi.encodePacked(_actionsToRoles[target][encodedSig][i])
                ) == keccak256(abi.encodePacked(role))
            ) {
                _actionsToRoles[target][encodedSig][i] = _actionsToRoles[
                    target
                ][encodedSig][rolesLength - 1];
                _actionsToRoles[target][encodedSig].pop();

                emit ActionRoleRemoved(target, functionDesc, encodedSig, role);

                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Reverts when msg.sender is not authorized to upgrade the contract
    /// @notice Only addresses that have the DAO_ROLE role are authorized
    /// @notice Called by upgradeTo and upgradeToAndCall
    /// @param newImplementation New implementation contract address being upgraded to
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DAO_ROLE)
    {}

    /// @notice Reverts with a standard message if account is missing role
    /// @param role Role being checked
    /// @param account Address that role is being checked on
    function _checkRole(string memory role, address account) internal view {
        if (!hasRole(role, account)) {
            revert MissingRole(account, role);
        }
    }
}