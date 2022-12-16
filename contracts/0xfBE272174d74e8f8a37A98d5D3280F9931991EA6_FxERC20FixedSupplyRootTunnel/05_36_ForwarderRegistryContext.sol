// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IForwarderRegistry} from "./interfaces/IForwarderRegistry.sol";
import {IERC2771} from "./interfaces/IERC2771.sol";
import {ForwarderRegistryContextBase} from "./base/ForwarderRegistryContextBase.sol";

/// @title Meta-Transactions Forwarder Registry Context (immutable version).
/// @dev This contract is to be used via inheritance in an immutable (non-proxied) implementation.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
abstract contract ForwarderRegistryContext is ForwarderRegistryContextBase, IERC2771 {
    constructor(IForwarderRegistry forwarderRegistry_) ForwarderRegistryContextBase(forwarderRegistry_) {}

    function forwarderRegistry() external view returns (IForwarderRegistry) {
        return _forwarderRegistry;
    }

    /// @inheritdoc IERC2771
    function isTrustedForwarder(address forwarder) external view virtual override returns (bool) {
        return forwarder == address(_forwarderRegistry);
    }
}