// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMigrationRegistry} from "../interfaces/IMigrationRegistry.sol";

/// @title meTokens Protocol Migration Registry
/// @author Carter Carlson (@cartercarlson)
/// @notice Contract which manages all migration routes for when a meToken
///         changes its' base asset.
contract MigrationRegistry is Ownable, IMigrationRegistry {
    // Initial vault => target vault => migration vault => approved status
    mapping(address => mapping(address => mapping(address => bool)))
        private _migrations;

    /// @inheritdoc IMigrationRegistry
    function approve(
        address initialVault,
        address targetVault,
        address migration
    ) external override onlyOwner {
        require(
            !_migrations[initialVault][targetVault][migration],
            "migration already approved"
        );
        _migrations[initialVault][targetVault][migration] = true;
        emit Approve(initialVault, targetVault, migration);
    }

    /// @inheritdoc IMigrationRegistry
    function unapprove(
        address initialVault,
        address targetVault,
        address migration
    ) external override onlyOwner {
        require(
            _migrations[initialVault][targetVault][migration],
            "migration not approved"
        );
        _migrations[initialVault][targetVault][migration] = false;
        emit Unapprove(initialVault, targetVault, migration);
    }

    /// @inheritdoc IMigrationRegistry
    function isApproved(
        address initialVault,
        address targetVault,
        address migration
    ) external view override returns (bool) {
        return _migrations[initialVault][targetVault][migration];
    }
}