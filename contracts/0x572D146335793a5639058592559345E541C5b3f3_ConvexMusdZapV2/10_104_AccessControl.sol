// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;

import {
    AccessControl as OZAccessControl
} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice Extends OpenZeppelin AccessControl contract with modifiers
 * @dev This contract and AccessControlUpgradeSafe are essentially duplicates.
 */
contract AccessControl is OZAccessControl {
    /** @notice access control roles **/
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant LP_ROLE = keccak256("LP_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    modifier onlyLpRole() {
        require(hasRole(LP_ROLE, _msgSender()), "NOT_LP_ROLE");
        _;
    }

    modifier onlyContractRole() {
        require(hasRole(CONTRACT_ROLE, _msgSender()), "NOT_CONTRACT_ROLE");
        _;
    }

    modifier onlyAdminRole() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "NOT_ADMIN_ROLE");
        _;
    }

    modifier onlyEmergencyRole() {
        require(hasRole(EMERGENCY_ROLE, _msgSender()), "NOT_EMERGENCY_ROLE");
        _;
    }

    modifier onlyLpOrContractRole() {
        require(
            hasRole(LP_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_LP_OR_CONTRACT_ROLE"
        );
        _;
    }

    modifier onlyAdminOrContractRole() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(CONTRACT_ROLE, _msgSender()),
            "NOT_ADMIN_OR_CONTRACT_ROLE"
        );
        _;
    }
}