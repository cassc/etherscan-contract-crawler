// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract UpgradeableBase is AccessControlUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    error NotManager();

    // keccak256("MANAGER_ROLE")
    bytes32 public constant MANAGER_ROLE = 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08;

    function __UpgradeableBase_init(address admin) internal onlyInitializing {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function _authorizeUpgrade(address) internal override onlyManager { }

    function pause() external onlyManager {
        super._pause();
    }

    function unpause() external onlyManager {
        super._unpause();
    }

    function _grantManagerRole(address _manager) internal {
        _grantRole(MANAGER_ROLE, _manager);
    }

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            revert NotManager();
        }

        _;
    }
}