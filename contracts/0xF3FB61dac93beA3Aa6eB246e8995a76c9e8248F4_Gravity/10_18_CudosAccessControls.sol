// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CudosAccessControls is AccessControl {
    // Role definitions
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant SMART_CONTRACT_ROLE = keccak256("SMART_CONTRACT_ROLE");
    // Events
    event AdminRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );
    event AdminRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );
    event WhitelistRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );
    event WhitelistRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );
    event SmartContractRoleGranted(
        address indexed beneficiary,
        address indexed caller
    );
    event SmartContractRoleRemoved(
        address indexed beneficiary,
        address indexed caller
    );
    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CudosAccessControls: sender must be an admin");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /////////////
    // Lookups //
    /////////////
    function hasAdminRole(address _address) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }
    function hasWhitelistRole(address _address) external view returns (bool) {
        return hasRole(WHITELISTED_ROLE, _address);
    }
    function hasSmartContractRole(address _address) external view returns (bool) {
        return hasRole(SMART_CONTRACT_ROLE, _address);
    }
    ///////////////
    // Modifiers //
    ///////////////
    function addAdminRole(address _address) external onlyAdminRole {
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleGranted(_address, _msgSender());
    }
    function removeAdminRole(address _address) external onlyAdminRole {
        revokeRole(DEFAULT_ADMIN_ROLE, _address);
        emit AdminRoleRemoved(_address, _msgSender());
    }
    function addWhitelistRole(address _address) external onlyAdminRole {
        _setupRole(WHITELISTED_ROLE, _address);
        emit WhitelistRoleGranted(_address, _msgSender());
    }
    function removeWhitelistRole(address _address) external onlyAdminRole {
        revokeRole(WHITELISTED_ROLE, _address);
        emit WhitelistRoleRemoved(_address, _msgSender());
    }
    function addSmartContractRole(address _address) external onlyAdminRole {
        _setupRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleGranted(_address, _msgSender());
    }
    function removeSmartContractRole(address _address) external onlyAdminRole {
        revokeRole(SMART_CONTRACT_ROLE, _address);
        emit SmartContractRoleRemoved(_address, _msgSender());
    }
}