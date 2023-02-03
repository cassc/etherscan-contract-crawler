// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";

abstract contract RegistryBase is AccessControlEnumerableUpgradeable {
    // STORAGE

    /// @dev Service address
    address public service;

    // MODIFIERS

    modifier onlyService() {
        require(msg.sender == service, ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    // INITIALIZER

    function __RegistryBase_init() internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // PUBLIC FUNCTIONS

    function setService(address service_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        service = service_;
    }
}