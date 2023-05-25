// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

/**
 * @title STBX | Stobox Technologies Common Stock
 * @author Stobox Technologies Inc.
 * @dev STBX ERC20 Token | This contract is opt for digital securities management.
 */

contract Roles is Ownable, AccessControl {
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 public constant FREEZER_ROLE = keccak256("FREEZER_ROLE");
    bytes32 public constant TRANSPORTER_ROLE = keccak256("TRANSPORTER_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE");
    bytes32 public constant LIMITER_ROLE = keccak256("LIMITER_ROLE");

    /**
     * @notice Add `_address` to the super admin role as a member.
     * @param _address Address to aad to the super admin role as a member.
     */
    constructor(address _address) public {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);

        _setRoleAdmin(WHITELISTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(FREEZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TRANSPORTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(VOTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(LIMITER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Modifiers
    modifier onlySuperAdmin() {
        require(isSuperAdmin(msg.sender), "Restricted to super admins.");
        _;
    }

    modifier onlyWhitelister() {
        require(isWhitelister(msg.sender), "Restricted to whitelisters.");
        _;
    }

    modifier onlyFreezer() {
        require(isFreezer(msg.sender), "Restricted to freezers.");
        _;
    }

    modifier onlyTransporter() {
        require(isTransporter(msg.sender), "Restricted to transporters.");
        _;
    }

    modifier onlyVoter() {
        require(isVoter(msg.sender), "Restricted to voters.");
        _;
    }

    modifier onlyLimiter() {
        require(isLimiter(msg.sender), "Restricted to limiters.");
        _;
    }

    // External functions

    /**
     * @notice Add the super admin role for the address.
     * @param _address Address for assigning the super admin role.
     */
    function addSuperAdmin(address _address) external onlySuperAdmin {
        _assignRole(_address, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @notice Add the whitelister role for the address.
     * @param _address Address for assigning the whitelister role.
     */
    function addWhitelister(address _address) external onlySuperAdmin {
        _assignRole(_address, WHITELISTER_ROLE);
    }

    /**
     * @notice Add the freezer role for the address.
     * @param _address Address for assigning the freezer role.
     */
    function addFreezer(address _address) external onlySuperAdmin {
        _assignRole(_address, FREEZER_ROLE);
    }

    /**
     * @notice Add the transporter role for the address.
     * @param _address Address for assigning the transporter role.
     */
    function addTransporter(address _address) external onlySuperAdmin {
        _assignRole(_address, TRANSPORTER_ROLE);
    }

    /**
     * @notice Add the voter role for the address.
     * @param _address Address for assigning the voter role.
     */
    function addVoter(address _address) external onlySuperAdmin {
        _assignRole(_address, VOTER_ROLE);
    }

    /**
     * @notice Add the limiter role for the address.
     * @param _address Address for assigning the limiter role.
     */
    function addLimiter(address _address) external onlySuperAdmin {
        _assignRole(_address, LIMITER_ROLE);
    }

    /**
     * @notice Renouncement of supera dmin role.
     */
    function renounceSuperAdmin() external onlySuperAdmin {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Remove the whitelister role for the address.
     * @param _address Address for removing the whitelister role.
     */
    function removeWhitelister(address _address) external onlySuperAdmin {
        _removeRole(_address, WHITELISTER_ROLE);
    }

    /**
     * @notice Remove the freezer role for the address.
     * @param _address Address for removing the freezer role.
     */
    function removeFreezer(address _address) external onlySuperAdmin {
        _removeRole(_address, FREEZER_ROLE);
    }

    /**
     * @notice Remove the transporter role for the address.
     * @param _address Address for removing the transporter role.
     */
    function removeTransporter(address _address) external onlySuperAdmin {
        _removeRole(_address, TRANSPORTER_ROLE);
    }

    /**
     * @notice Remove the voter role for the address.
     * @param _address Address for removing the voter role.
     */
    function removeVoter(address _address) external onlySuperAdmin {
        _removeRole(_address, VOTER_ROLE);
    }

    /**
     * @notice Remove the limiter role for the address.
     * @param _address Address for removing the limiter role.
     */
    function removeLimiter(address _address) external onlySuperAdmin {
        _removeRole(_address, LIMITER_ROLE);
    }

    // Public functions

    /**
     * @notice Checks if the address is assigned the super admin role.
     * @param _address Address for checking.
     */
    function isSuperAdmin(address _address) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the whitelister role.
     * @param _address Address for checking.
     */
    function isWhitelister(address _address)
        public
        view
        virtual
        returns (bool)
    {
        return hasRole(WHITELISTER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the freezer role.
     * @param _address Address for checking.
     */
    function isFreezer(address _address) public view virtual returns (bool) {
        return hasRole(FREEZER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the transporter role.
     * @param _address Address for checking.
     */
    function isTransporter(address _address)
        public
        view
        virtual
        returns (bool)
    {
        return hasRole(TRANSPORTER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the voter role.
     * @param _address Address for checking.
     */
    function isVoter(address _address) public view virtual returns (bool) {
        return hasRole(VOTER_ROLE, _address);
    }

    /**
     * @notice Checks if the address is assigned the limiter role.
     * @param _address Address for checking.
     */
    function isLimiter(address _address) public view virtual returns (bool) {
        return hasRole(LIMITER_ROLE, _address);
    }

    // Private functions

    /**
     * @notice Add the `_role` for the `_address`.
     * @param _role Role to assigning for the `_address`.
     * @param _address Address for assigning the `_role`.
     */
    function _assignRole(address _address, bytes32 _role) private {
        grantRole(_role, _address);
    }

    /**
     * @notice Remove the `_role` from the `_address`.
     * @param _role Role to removing from the `_address`.
     * @param _address Address for removing the `_role`.
     */
    function _removeRole(address _address, bytes32 _role) private {
        revokeRole(_role, _address);
    }
}