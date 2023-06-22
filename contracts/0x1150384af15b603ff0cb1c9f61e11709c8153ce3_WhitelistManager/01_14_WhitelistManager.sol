// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-upgradeable/security/PausableUpgradeable.sol";

import {ISanctionsList} from "../interfaces/IWhitelistManager.sol";

import "../config/errors.sol";

contract WhitelistManager is OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant CUSTOMER_ROLE = keccak256("CUSTOMER_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
    bytes32 public constant OTC_ROLE = keccak256("OTC_ROLE");
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");

    /*///////////////////////////////////////////////////////////////
                            State Variables V1
    //////////////////////////////////////////////////////////////*/

    address public sanctionsOracle;

    mapping(bytes32 => mapping(address => bool)) public permissions;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor() {}

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        _transferOwnership(_owner);
        __Pausable_init();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new oracle address
     * @param _sanctionsOracle is the address of the new oracle
     */
    function setSanctionsOracle(address _sanctionsOracle) external {
        _checkOwner();

        if (_sanctionsOracle == address(0)) revert BadAddress();

        sanctionsOracle = _sanctionsOracle;
    }

    /**
     * @notice Checks if customer has been whitelisted
     * @param _address the address of the account
     * @return value returning if allowed to transact
     */
    function isCustomer(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(CUSTOMER_ROLE, _address);
    }

    /**
     * @notice Checks if LP has been whitelisted
     * @param _address the address of the LP Wallet
     * @return value returning if allowed to transact
     */
    function isLP(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(LP_ROLE, _address);
    }

    /**
     * @notice Checks if Vault has been whitelisted
     * @param _address the address of the Vault
     * @return value returning if allowed to transact
     */
    function isVault(address _address) external view returns (bool) {
        return _hasRole(VAULT_ROLE, _address);
    }

    /*
     * @notice Checks if OTC has been whitelisted
     * @param _address the address of the OTC
     * @return value returning if allowed to transact
     */
    function isOTC(address _address) external view returns (bool) {
        return _hasRoleAndNotSanctioned(OTC_ROLE, _address);
    }

    /*
     * @notice Checks if Smart Contract has been whitelisted
     * @param _address the address of the contract
     * @return value returning if allowed to transact
     */
    function isSystem(address _address) external view returns (bool) {
        return _hasRole(SYSTEM_ROLE, _address);
    }

    /**
     * @notice Checks if address has been whitelisted
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function isAllowed(address _address) public view returns (bool) {
        // Vaults / Systems are internal,
        // realistically they would not be sanctioned
        if (_hasRole(VAULT_ROLE, _address)) return true;
        if (_hasRole(SYSTEM_ROLE, _address)) return true;

        if (_sanctioned(_address)) return false;

        if (_hasRole(CUSTOMER_ROLE, _address)) return true;
        if (_hasRole(LP_ROLE, _address)) return true;

        return false;
    }

    /**
     * @notice Checks if address can interact with tokens
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasTokenPrivileges(address _address) public view returns (bool) {
        // Vaults / Systems are internal,
        // realistically they would not be sanctioned
        if (_hasRole(VAULT_ROLE, _address)) return true;
        if (_hasRole(SYSTEM_ROLE, _address)) return true;

        if (_sanctioned(_address)) return false;

        if (_hasRole(CUSTOMER_ROLE, _address)) return true;

        return false;
    }

    function grantRole(bytes32 role, address _address) external {
        _checkOwner();

        permissions[role][_address] = true;

        emit RoleGranted(role, _address, _msgSender());
    }

    function revokeRole(bytes32 role, address _address) external {
        _checkOwner();

        permissions[role][_address] = false;

        emit RoleRevoked(role, _address, _msgSender());
    }

    /**
     * @notice Checks if an address has a specific role and is not sanctioned
     * @param _role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRoleAndNotSanctioned(bytes32 _role, address _address) public view returns (bool) {
        return _hasRoleAndNotSanctioned(_role, _address);
    }

    /**
     * @notice Checks if an address has a specific role
     * @param _role the the specific role
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function hasRole(bytes32 _role, address _address) public view returns (bool) {
        return _hasRole(_role, _address);
    }

    /**
     * @notice Pauses whitelist
     * @dev reverts on any check of permissions preventing any movement of funds
     *      between vault, auction, and option protocol
     */
    function pause() public {
        _checkOwner();

        _pause();
    }

    /**
     * @notice Unpauses whitelist
     */
    function unpause() public {
        _checkOwner();

        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _hasRole(bytes32 _role, address _address) internal view returns (bool) {
        if (paused()) revert WL_Paused();

        if (_role == bytes32(0)) revert WL_BadRole();
        if (_address == address(0)) revert BadAddress();
        return permissions[_role][_address];
    }

    function _hasRoleAndNotSanctioned(bytes32 _role, address _address) internal view returns (bool) {
        return _hasRole(_role, _address) && !_sanctioned(_address);
    }

    /**
     * @notice Checks if an address is sanctioned
     * @param _address the address
     * @return value returning if allowed to transact
     */
    function _sanctioned(address _address) internal view returns (bool) {
        if (_address == address(0)) revert BadAddress();

        return sanctionsOracle != address(0) ? ISanctionsList(sanctionsOracle).isSanctioned(_address) : false;
    }

    function _checkOwner() internal view override {
        if (owner() != _msgSender()) revert Unauthorized();
    }
}