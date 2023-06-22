// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAddressesRegistry} from "../interfaces/IAddressesRegistry.sol";
import {IAccessManager} from "../interfaces/IAccessManager.sol";
import {Errors} from "../libraries/Errors.sol";

/**
 * @title AccessManager
 * @author Souq.Finance
 * @notice The Souq AccessControl Manager. Saves and Lists all admins.
 * @notice License: https://souq-peripheral-v1.s3.amazonaws.com/LICENSE.md
 */
contract AccessManager is AccessControl, IAccessManager {
    bytes32 public constant override POOL_ADMIN_ROLE = keccak256("POOL_ADMIN");
    bytes32 public constant override POOL_OPERATIONS_ROLE = keccak256("POOL_OPERATIONS_ROLE");
    bytes32 public constant override EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN");
    bytes32 public constant override ORACLE_ADMIN_ROLE = keccak256("ORACLE_ADMIN_ROLE");
    bytes32 public constant override CONNECTOR_ROUTER_ADMIN_ROLE = keccak256("CONNECTOR_ROUTER_ADMIN_ROLE");
    bytes32 public constant override STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE = keccak256("STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE");
    bytes32 public constant override STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE = keccak256("STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE");
    bytes32 public constant override UPGRADER_ADMIN_ROLE = keccak256("UPGRADER_ADMIN_ROLE");
    bytes32 public constant override TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    uint256 public constant ACCESS_MANAGER_VERSION = 1;

    IAddressesRegistry public immutable ADDRESSES_PROVIDER;

    constructor(IAddressesRegistry _ADDRESSES_PROVIDER) {
        require(
            address(_ADDRESSES_PROVIDER) != address(0) && IAddressesRegistry(_ADDRESSES_PROVIDER).getAccessAdmin() != address(0),
            "AccessManager: Invalid Addresses Provider address"
        );
        ADDRESSES_PROVIDER = _ADDRESSES_PROVIDER;
        _setupRole(DEFAULT_ADMIN_ROLE, IAddressesRegistry(_ADDRESSES_PROVIDER).getAccessAdmin());
    }

    /**
     * @dev modifier for when the address is the access admin
     */
    modifier onlyAccessAdmin() {
        require(IAddressesRegistry(ADDRESSES_PROVIDER).getAccessAdmin() == msg.sender, Errors.CALLER_NOT_ACCESS_ADMIN);
        _;
    }

    /// @inheritdoc IAccessManager
    function changeDefaultAdmin(address _admin) external onlyAccessAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @inheritdoc IAccessManager
    function getVersion() external pure returns (uint256) {
        return ACCESS_MANAGER_VERSION;
    }

    /// @inheritdoc IAccessManager
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external onlyAccessAdmin {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IAccessManager
    function addPoolAdmin(address admin) external onlyAccessAdmin {
        grantRole(POOL_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removePoolAdmin(address admin) external onlyAccessAdmin {
        revokeRole(POOL_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isPoolAdmin(address admin) external view returns (bool) {
        return hasRole(POOL_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addPoolOperations(address admin) external onlyAccessAdmin {
        grantRole(POOL_OPERATIONS_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removePoolOperations(address admin) external onlyAccessAdmin {
        revokeRole(POOL_OPERATIONS_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isPoolOperations(address admin) external view returns (bool) {
        return hasRole(POOL_OPERATIONS_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addEmergencyAdmin(address admin) external onlyAccessAdmin {
        grantRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removeEmergencyAdmin(address admin) external onlyAccessAdmin {
        revokeRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isEmergencyAdmin(address admin) external view returns (bool) {
        return hasRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addOracleAdmin(address admin) external onlyAccessAdmin {
        grantRole(ORACLE_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removeOracleAdmin(address admin) external onlyAccessAdmin {
        revokeRole(ORACLE_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isOracleAdmin(address admin) external view returns (bool) {
        return hasRole(ORACLE_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addConnectorAdmin(address admin) external onlyAccessAdmin {
        grantRole(CONNECTOR_ROUTER_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removeConnectorAdmin(address admin) external onlyAccessAdmin {
        revokeRole(CONNECTOR_ROUTER_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isConnectorAdmin(address admin) external view returns (bool) {
        return hasRole(CONNECTOR_ROUTER_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addStablecoinYieldAdmin(address admin) external onlyAccessAdmin {
        grantRole(STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removeStablecoinYieldAdmin(address admin) external onlyAccessAdmin {
        revokeRole(STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isStablecoinYieldAdmin(address admin) external view returns (bool) {
        return hasRole(STABLECOIN_YIELD_CONNECTOR_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addStablecoinYieldLender(address lender) external onlyAccessAdmin {
        grantRole(STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE, lender);
    }

    /// @inheritdoc IAccessManager
    function removeStablecoinYieldLender(address lender) external onlyAccessAdmin {
        revokeRole(STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE, lender);
    }

    /// @inheritdoc IAccessManager
    function isStablecoinYieldLender(address lender) external view returns (bool) {
        return hasRole(STABLECOIN_YIELD_CONNECTOR_LENDER_ROLE, lender);
    }

    /// @inheritdoc IAccessManager
    function addUpgraderAdmin(address admin) external onlyAccessAdmin {
        grantRole(UPGRADER_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removeUpgraderAdmin(address admin) external onlyAccessAdmin {
        revokeRole(UPGRADER_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isUpgraderAdmin(address admin) external view returns (bool) {
        return hasRole(UPGRADER_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function addTimelockAdmin(address admin) external onlyAccessAdmin {
        grantRole(TIMELOCK_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function removeTimelockAdmin(address admin) external onlyAccessAdmin {
        revokeRole(TIMELOCK_ADMIN_ROLE, admin);
    }

    /// @inheritdoc IAccessManager
    function isTimelockAdmin(address admin) external view returns (bool) {
        return hasRole(TIMELOCK_ADMIN_ROLE, admin);
    }
}