// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC2771} from "./../interfaces/IERC2771.sol";
import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";

/// @title Meta-Transactions Forwarder Registry Context (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
contract ForwarderRegistryContextFacet is IERC2771 {
    IForwarderRegistry public immutable forwarderRegistry;

    constructor(IForwarderRegistry forwarderRegistry_) {
        forwarderRegistry = forwarderRegistry_;
    }

    /// @inheritdoc IERC2771
    function isTrustedForwarder(address forwarder) external view virtual override returns (bool) {
        return forwarder == address(forwarderRegistry);
    }
}