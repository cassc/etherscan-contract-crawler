// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./IACL.sol";
import "./Roles.sol";
import "../common/BlockAware.sol";

/// @title Access Control List contract
contract ACL is IACL, AccessControlEnumerableUpgradeable, UUPSUpgradeable, BlockAware {
    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        if (Roles.ADMIN != DEFAULT_ADMIN_ROLE) revert RolesContractIncorrectlyConfigured();
    }

    function initialize(address admin) external initializer {
        // solhint-disable-previous-line comprehensive-interface
        __UUPSUpgradeable_init();
        __AccessControlEnumerable_init();
        __BlockAware_init();

        // Set up roles
        _grantRole(Roles.ADMIN, admin);
    }

    /// @inheritdoc IACL
    function checkRole(bytes32 role, address account) external view override {
        _checkRole(role, account);
    }

    /// @inheritdoc IACL
    function getAdminRole() external pure override returns (bytes32) {
        return Roles.ADMIN;
    }

    /// @inheritdoc IACL
    function getMaintainerRole() external pure override returns (bytes32) {
        return Roles.MAINTAINER;
    }

    /// @inheritdoc AccessControlEnumerableUpgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // Explicitly declare which super-class to use
        return interfaceId == type(IACL).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc AccessControlEnumerableUpgradeable
    function _grantRole(bytes32 role, address account) internal virtual override {
        if (role == Roles.NFT_OWNER && getRoleMemberCount(role) > 0) revert CannotHaveMoreThanOneAddressInRole();

        super._grantRole(role, account);
    }

    /// @inheritdoc AccessControlEnumerableUpgradeable
    function _revokeRole(bytes32 role, address account) internal virtual override {
        if (role == Roles.ADMIN && getRoleMemberCount(role) == 1) revert CannotRemoveLastAdmin();

        super._revokeRole(role, account);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        // solhint-disable-previous-line no-empty-blocks
    }
}