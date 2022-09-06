// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title VTableBeacon
 * @notice Redirects calls to an implementation based on the method signature
 */
contract VTableBeacon is Ownable {
    struct ModuleDefinition {
        address implementation;
        bytes4[] selectors;
    }

    bytes4 private constant _FALLBACK_SIGN = 0xffffffff;

    // Mapping of methods signatures to their implementations
    mapping(bytes4 => address) public delegates;

    event VTableUpdate(bytes4 indexed selector, address oldImplementation, address newImplementation);

    function implementation(bytes4 _selector) external view virtual returns (address module) {
        module = delegates[_selector];
        if (module != address(0)) return module;

        module = delegates[_FALLBACK_SIGN];
        if (module != address(0)) return module;

        revert('VTableBeacon: No implementation found');
    }

    /**
     * @dev Updates the vtable
     */
    function updateVTable(ModuleDefinition[] calldata modules) external onlyOwner {
        for (uint256 i = 0; i < modules.length; ++i) {
            ModuleDefinition memory module = modules[i];
            for (uint256 j = 0; j < module.selectors.length; ++j) {
                bytes4 selector = module.selectors[j];
                emit VTableUpdate(selector, delegates[selector], module.implementation);
                delegates[selector] = module.implementation;
            }
        }
    }
}