// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

import "../../lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "./ICorePermissions.sol";

/// @title Access control module for Core
/// @author Recursive Research Inc
abstract contract CorePermissions is ICorePermissions, AccessControlUpgradeable {
    bytes32 public constant override GOVERN_ROLE = keccak256("GOVERN_ROLE");
    bytes32 public constant override GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant override PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant override STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
    bytes32 public constant override WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bool public override whitelistDisabled;

    /// @dev Initializer. Grants the initial access roles and
    /// @param governor intitial governor
    /// @param guardian initial guardian
    /// @param pauser initial pauser
    /// @param strategist initial strategist
    function __CorePermissions_init(
        address governor,
        address guardian,
        address pauser,
        address strategist
    ) internal onlyInitializing {
        __AccessControl_init();
        __CorePermissions_init_unchained(governor, guardian, pauser, strategist);
    }

    function __CorePermissions_init_unchained(
        address governor,
        address guardian,
        address pauser,
        address strategist
    ) internal onlyInitializing {
        _setRoleAdmin(GOVERN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, GOVERN_ROLE);
        _setRoleAdmin(PAUSE_ROLE, GOVERN_ROLE);
        _setRoleAdmin(STRATEGIST_ROLE, GOVERN_ROLE);
        _setRoleAdmin(WHITELISTED_ROLE, GOVERN_ROLE);

        _grantRole(GOVERN_ROLE, governor);
        _grantRole(GUARDIAN_ROLE, guardian);
        _grantRole(PAUSE_ROLE, pauser);
        _grantRole(STRATEGIST_ROLE, strategist);
    }

    /// @notice creates a new role to be maintained
    /// @param role the new role id
    /// @param adminRole the admin role id for `role`
    /// @dev can also be used to update admin of existing role
    function createRole(bytes32 role, bytes32 adminRole) external override onlyRole(GOVERN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    /// @notice Batch updates the whitelist
    /// @param addresses list of addresses to whitelist
    function whitelistAll(address[] memory addresses) external override onlyRole(GOVERN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            _grantRole(WHITELISTED_ROLE, addresses[i]);
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        override(IAccessControlUpgradeable, AccessControlUpgradeable)
        onlyRole(getRoleAdmin(role))
    {
        // this ensures that there is at least one GOVERN_ROLE role (last governor cannot self-revoke)
        require(msg.sender != account, "NO_SELFREVOKE");
        _revokeRole(role, account);
    }

    function isWhitelisted(address _address) public view override returns (bool) {
        return whitelistDisabled || hasRole(WHITELISTED_ROLE, _address);
    }

    function disableWhitelist() external override onlyRole(GOVERN_ROLE) {
        if (!whitelistDisabled) {
            whitelistDisabled = true;
            emit WhitelistDisabled();
        }
    }

    function enableWhitelist() external override onlyRole(GOVERN_ROLE) {
        if (whitelistDisabled) {
            whitelistDisabled = false;
            emit WhitelistEnabled();
        }
    }
}