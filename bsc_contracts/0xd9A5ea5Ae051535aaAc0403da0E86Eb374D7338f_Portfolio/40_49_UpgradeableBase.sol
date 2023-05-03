// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { AccessControlUpgradeable } from
    "openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";

abstract contract UpgradeableBase is AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    error NotManager();

    // keccak256("PAUSER_ROLE")
    bytes32 public constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;

    // keccak256("MANAGER_ROLE")
    bytes32 public constant MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08;

    function __UpgradeableBase_init(address admin, address pauser) internal onlyInitializing {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) { }

    function pause() external onlyRole(PAUSER_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        super._unpause();
    }

    function _grantManagerRole(address _manager) internal {
        _grantRole(MANAGER_ROLE, _manager);
    }

    function _requireManagerRole() internal view {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            revert NotManager();
        }
    }
}