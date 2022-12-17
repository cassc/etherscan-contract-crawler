/// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./utils/Constants.sol";
import "./interfaces/IMetaWealthAccessControlled.sol";

contract MetaWealthAccessControlled is
    Initializable,
    AccessControlUpgradeable,
    IMetaWealthAccessControlled
{
    /// @notice Modifier to check if caller is super admin or not
    modifier onlySuperAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "MetaWealthAccessControl: Resctricted to Admins"
        );
        _;
    }

    /// @notice Modifier to check if caller is an admin
    modifier onlyAdminOrSuperAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "MetaWealthAccessControl: Resctricted to Admins"
        );
        _;
    }
    /// @notice Modifier to check if caller is an admin
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "MetaWealthAccessControl: Resctricted to Admins"
        );
        _;
    }

    function __RoleControl_init(address root) internal onlyInitializing {
        __RoleControl_init_unchained(root);
    }

    /// @notice Instantiate the smart contract with necessary roles
    function __RoleControl_init_unchained(
        address root
    ) internal onlyInitializing {
        __AccessControl_init();

        // root is DEFAULT_ADMIN_ROLE
        _setupRole(DEFAULT_ADMIN_ROLE, root);

        // DEFAULT_ADMIN_ROLE can manage ADMINs
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        // set ADMIN
        _setupRole(ADMIN_ROLE, root);

        // DEFAULT_ADMIN_ROLE can manage ASEET_VAULT_MANAGERs
        _setRoleAdmin(ASSET_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        // ADMIN_ROLE can manage ASEET_VAULT_MANAGERs
        _setRoleAdmin(ASSET_MANAGER_ROLE, ADMIN_ROLE);

        // set ASSET_MANAGER
        _setupRole(ASSET_MANAGER_ROLE, root);
    }

    function isSuperAdmin(address _account) public view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function isAdmin(address _account) public view override returns (bool) {
        return hasRole(ADMIN_ROLE, _account);
    }

    function isAssetManager(address _account) public view override returns (bool) {
        return hasRole(ASSET_MANAGER_ROLE, _account);
    }

    function setAdmin(address newAccount) external override onlySuperAdmin {
        _setupRole(ADMIN_ROLE, newAccount);
        _revokeRole(ADMIN_ROLE, _msgSender());
        emit AdminChanged(_msgSender(), newAccount, false);
    }

    function setSuperAdmin(
        address newAccount
    ) external override onlySuperAdmin {
        require(
            newAccount != address(0),
            "RoleControl: invalid minter address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, newAccount);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        emit AdminChanged(_msgSender(), newAccount, true);
    }

    function setAssetManager(
        address _account,
        bool enabled
    ) external override onlyAdminOrSuperAdmin {
        require(_account != address(0), "RoleControl: invalid address");
        if (enabled) _setupRole(ASSET_MANAGER_ROLE, _account);
        else _revokeRole(ASSET_MANAGER_ROLE, _account);
    }

    uint256[50] private __gap;
}