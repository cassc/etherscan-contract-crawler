// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./registry/CompaniesRegistry.sol";
import "./registry/RecordsRegistry.sol";
import "./registry/TokensRegistry.sol";

/// @dev The repository of all user and business entities created by the protocol: companies to be implemented, contracts to be deployed, proposal created by shareholders.
contract Registry is CompaniesRegistry, RecordsRegistry, TokensRegistry {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer
     */
    function initialize() public initializer {
        __RegistryBase_init();
    }
}