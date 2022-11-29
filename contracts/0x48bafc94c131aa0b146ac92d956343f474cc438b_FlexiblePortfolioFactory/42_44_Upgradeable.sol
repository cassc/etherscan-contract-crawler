// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControlEnumerableUpgradeable} from "AccessControlEnumerableUpgradeable.sol";
import {UUPSUpgradeable} from "UUPSUpgradeable.sol";
import {PausableUpgradeable} from "PausableUpgradeable.sol";

abstract contract Upgradeable is AccessControlEnumerableUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() initializer {}

    function __Upgradeable_init(address admin, address pauser) internal onlyInitializing {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function pause() external onlyRole(PAUSER_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        super._unpause();
    }
}