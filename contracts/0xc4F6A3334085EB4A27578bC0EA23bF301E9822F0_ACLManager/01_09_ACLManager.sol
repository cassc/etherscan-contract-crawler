// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IACLManager.sol';

contract ACLManager is IACLManager, AccessControl, Ownable {
    bytes32 public constant POOL_ADMIN_ROLE = keccak256('POOL_ADMIN');
    
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256('EMERGENCY_ADMIN');

    bytes32 public constant GOVERNANCE_ROLE = keccak256('GOVERNANCE');

    bytes32 public constant LIQUIDATOR_ROLE = keccak256('LIQUIDATOR');

    bytes32 public constant LIQUIDATION_OPERATOR = keccak256('LIQUIDATION_OPERATOR');

    bytes32 public constant AIRDROP_OPERATOR = keccak256('AIRDROP_OPERATOR');

    constructor() Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());
    }
    
    function addEmergencyAdmin(address admin) external override {
        grantRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    function isEmergencyAdmin(address admin) external view override returns (bool) {
        return hasRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    function removeEmergencyAdmin(address admin) external override {
        revokeRole(EMERGENCY_ADMIN_ROLE, admin);
    }

    function addGovernance(address admin) external override {
        grantRole(GOVERNANCE_ROLE, admin);
    }

    function isGovernance(address admin) external view override returns (bool) {
        return hasRole(GOVERNANCE_ROLE, admin);
    }

    function removeGovernance(address admin) external override {
        revokeRole(GOVERNANCE_ROLE, admin);
    }

    function addPoolAdmin(address poolAdmin) external override {
        grantRole(POOL_ADMIN_ROLE, poolAdmin);
    }

    function isPoolAdmin(address poolAdmin) external view override returns (bool) {
        return hasRole(POOL_ADMIN_ROLE, poolAdmin);
    }

    function removePoolAdmin(address poolAdmin) external override {
        revokeRole(POOL_ADMIN_ROLE, poolAdmin);
    }

    function addLiquidationOperator(address address_) external override {
        grantRole(LIQUIDATION_OPERATOR, address_);
    }

    function isLiquidationOperator(address address_) external view override returns (bool) {
        return hasRole(LIQUIDATION_OPERATOR, address_);
    }

    function removeLiquidationOperator(address address_) external override {
        revokeRole(LIQUIDATION_OPERATOR, address_);
    }

    function addAirdropOperator(address address_) external override {
        grantRole(AIRDROP_OPERATOR, address_);
    }

    function isAirdropOperator(address address_) external view override returns (bool) {
        return hasRole(AIRDROP_OPERATOR, address_);
    }

    function removeAirdropOperator(address address_) external override {
        revokeRole(AIRDROP_OPERATOR, address_);
    }
    
}