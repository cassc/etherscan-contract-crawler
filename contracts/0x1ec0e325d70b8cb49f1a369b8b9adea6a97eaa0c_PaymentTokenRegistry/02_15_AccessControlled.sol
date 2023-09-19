// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

import "./AccessController.sol";
import "./Errors.sol";

contract AccessControlled {
    AccessController public access;

    constructor(address accessController_) {
        if (accessController_ == address(0)) revert Errors.NullAddressNotAllowed();
        access = AccessController(accessController_);
    }

    modifier onlyAdmin() {
        _checkRole(access.ADMIN_ROLE());
        _;
    }

    modifier onlyAddressManager() {
        _checkRole(access.ADDRESS_MANAGER_ROLE());
        _;
    }

    modifier onlyOnboardingManager() {
        _checkRole(access.ONBOARDING_MANAGER_ROLE());
        _;
    }

    modifier onlyPaymentManager() {
        _checkRole(access.PAYMENT_MANAGER_ROLE());
        _;
    }

    modifier onlyReplicanManager() {
        _checkRole(access.REPLICAN_MANAGER_ROLE());
        _;
    }

    modifier onlyMetadataManager() {
        _checkRole(access.METADATA_MANAGER_ROLE());
        _;
    }

    function _checkRole(bytes32 role) private view {
        access.checkRole(role, msg.sender);
    }
}