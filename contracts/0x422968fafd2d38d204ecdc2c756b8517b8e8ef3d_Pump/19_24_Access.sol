// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessStorageExt} from "./AccessStorageExt.sol";

contract Access is UUPSUpgradeable, AccessControlUpgradeable, AccessStorageExt {

    function __Access_init(address _admin) internal onlyInitializing  {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        __AccessControl_init();
    }

    function _authorizeUpgrade(address) internal virtual override {
        _checkRole(DEFAULT_ADMIN_ROLE);
    }
}