// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract RolesUpgradeable is Initializable, ContextUpgradeable {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");


    function __Roles_init() internal onlyInitializing {
        __Roles_init_unchained();
    }

    function __Roles_init_unchained() internal onlyInitializing {
    }
}