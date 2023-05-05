// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';

import './IRegistry.sol';

/**
 * @title Registry
 * @dev Registry of contracts that acts as a curated list of implementations and instances to be trusted by the Mimic
 * protocol. Here consumers can find either implementation contracts (to be cloned through proxies) and contract
 * instances (from cloned implementations).
 *
 * The registry follows the Authorizer mixin and only authorized parties are allowed to register implementations.
 */
contract Registry is IRegistry, Authorizer {
    struct ImplementationData {
        bool stateless;
        bool deprecated;
        bytes32 namespace;
    }

    // List of implementations indexed by address
    mapping (address => ImplementationData) public override implementationData;

    /**
     * @dev Initializes the Registry contract
     * @param admin Address to be granted with register, deprecate, authorize, and unauthorize permissions
     */
    constructor(address admin) {
        _authorize(admin, Registry.register.selector);
        _authorize(admin, Registry.deprecate.selector);
        _authorize(admin, Authorizer.authorize.selector);
        _authorize(admin, Authorizer.unauthorize.selector);
    }

    /**
     * @dev Tells if a specific implementation is registered under a certain namespace and it's not deprecated
     * @param namespace Namespace asking for
     * @param implementation Address of the implementation to be checked
     */
    function isActive(bytes32 namespace, address implementation) external view override returns (bool) {
        ImplementationData storage data = implementationData[implementation];
        return !data.deprecated && data.namespace == namespace;
    }

    /**
     * @dev Registers a new implementation for a given namespace. Sender must be authorized.
     * @param namespace Namespace to be used for the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the implementation is stateless or not
     */
    function register(bytes32 namespace, address implementation, bool stateless) external override auth {
        require(namespace != bytes32(0), 'INVALID_NAMESPACE');
        require(implementation != address(0), 'INVALID_IMPLEMENTATION');

        ImplementationData storage data = implementationData[implementation];
        require(data.namespace == bytes32(0), 'REGISTERED_IMPLEMENTATION');

        data.deprecated = false;
        data.stateless = stateless;
        data.namespace = namespace;
        emit Registered(namespace, implementation, stateless);
    }

    /**
     * @dev Deprecates a registered implementation. Sender must be authorized.
     * @param implementation Address of the implementation to be deprecated. It must be registered and not deprecated.
     */
    function deprecate(address implementation) external override auth {
        require(implementation != address(0), 'IMPLEMENTATION_ADDRESS_ZERO');

        ImplementationData storage data = implementationData[implementation];
        require(data.namespace != bytes32(0), 'UNREGISTERED_IMPLEMENTATION');
        require(!data.deprecated, 'DEPRECATED_IMPLEMENTATION');

        data.deprecated = true;
        emit Deprecated(data.namespace, implementation);
    }
}