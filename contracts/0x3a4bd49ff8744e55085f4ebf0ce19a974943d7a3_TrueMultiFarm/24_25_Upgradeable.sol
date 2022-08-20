// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControlEnumerableUpgradeable} from "AccessControlEnumerableUpgradeable.sol";
import {UUPSUpgradeable} from "UUPSUpgradeable.sol";

abstract contract Upgradeable is AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    constructor() initializer {}

    function __Upgradeable_init(address admin) internal onlyInitializing {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}