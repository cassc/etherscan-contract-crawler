// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";
import {ERC2771Context} from "./ERC2771Context.sol";
import {EIP1967Upgradeable, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "./EIP1967Upgradeable.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

abstract contract FirmBase is EIP1967Upgradeable, ERC2771Context, IModuleMetadata {
    event Initialized(ISafe indexed safe, IModuleMetadata indexed implementation);

    function __init_firmBase(ISafe safe_, address trustedForwarder_) internal {
        // checks-effects-interactions violated so that the init event always fires first
        emit Initialized(safe_, _implementation());

        __init_setSafe(safe_);
        if (trustedForwarder_ != address(0) || trustedForwarder_ != IMPL_INIT_NOOP_ADDR) {
            _setTrustedForwarder(trustedForwarder_, true);
        }
    }
}