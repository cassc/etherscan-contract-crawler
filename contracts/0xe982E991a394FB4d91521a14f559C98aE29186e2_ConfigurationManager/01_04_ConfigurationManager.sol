// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IConfigurationManager } from "../interfaces/IConfigurationManager.sol";

/**
 * @title ConfigurationManager
 * @author Pods Finance
 * @notice Allows contracts to read protocol-wide settings
 */
contract ConfigurationManager is IConfigurationManager, Ownable {
    mapping(address => mapping(bytes32 => uint256)) private _parameters;
    mapping(address => uint256) private _caps;
    mapping(address => address) private _allowedVaults;
    address private immutable _global = address(0);

    /**
     * @inheritdoc IConfigurationManager
     */
    function setParameter(
        address target,
        bytes32 name,
        uint256 value
    ) public override onlyOwner {
        _parameters[target][name] = value;
        emit ParameterSet(target, name, value);
    }

    /**
     * @inheritdoc IConfigurationManager
     */
    function getParameter(address target, bytes32 name) external view override returns (uint256) {
        return _parameters[target][name];
    }

    /**
     * @inheritdoc IConfigurationManager
     */
    function getGlobalParameter(bytes32 name) external view override returns (uint256) {
        return _parameters[_global][name];
    }

    /**
     * @inheritdoc IConfigurationManager
     */
    function setCap(address target, uint256 value) external override onlyOwner {
        if (target == address(0)) revert ConfigurationManager__TargetCannotBeTheZeroAddress();
        _caps[target] = value;
        emit SetCap(target, value);
    }

    /**
     * @inheritdoc IConfigurationManager
     */
    function getCap(address target) external view override returns (uint256) {
        return _caps[target];
    }

    /**
     * @inheritdoc IConfigurationManager
     */
    function setVaultMigration(address oldVault, address newVault) external override onlyOwner {
        if (newVault == address(0)) revert ConfigurationManager__NewVaultCannotBeTheZeroAddress();
        _allowedVaults[oldVault] = newVault;
        emit VaultAllowanceSet(oldVault, newVault);
    }

    /**
     * @inheritdoc IConfigurationManager
     */
    function getVaultMigration(address oldVault) external view override returns (address) {
        return _allowedVaults[oldVault];
    }
}