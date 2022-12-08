// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

abstract contract ManageableUpgradeable is AccessControlEnumerableUpgradeable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    function __Manageable_init() internal onlyInitializing {
        __AccessControl_init_unchained();
        __Manageable_init_unchained();
    }

    function __Manageable_init_unchained() internal onlyInitializing {
    }
}