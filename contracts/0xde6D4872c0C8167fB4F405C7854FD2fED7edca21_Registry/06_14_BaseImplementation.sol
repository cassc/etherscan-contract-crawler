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

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

import './IImplementation.sol';
import '../registry/IRegistry.sol';

/**
 * @title BaseImplementation
 * @dev This implementation contract comes with an immutable reference to an implementations registry where it should
 * be registered as well (checked during initialization). It allows requesting new instances of other registered
 * implementations to as another safety check to make sure valid instances are referenced in case it's needed.
 */
abstract contract BaseImplementation is IImplementation {
    // Immutable implementations registry reference
    address public immutable override registry;

    /**
     * @dev Creates a new BaseImplementation
     * @param _registry Address of the Mimic Registry where dependencies will be validated against
     */
    constructor(address _registry) {
        registry = _registry;
    }

    /**
     * @dev Internal function to validate a new dependency that must be registered as stateless.
     * It checks the new dependency is registered, not deprecated, and stateless.
     * @param dependency New stateless dependency to be set
     */
    function _validateStatelessDependency(address dependency) internal view {
        require(_validateDependency(dependency), 'DEPENDENCY_NOT_STATELESS');
    }

    /**
     * @dev Internal function to validate a new dependency that cannot be registered as stateless.
     * It checks the new dependency is registered, not deprecated, and not stateful.
     * @param dependency New stateful dependency to be set
     */
    function _validateStatefulDependency(address dependency) internal view {
        require(!_validateDependency(dependency), 'DEPENDENCY_NOT_STATEFUL');
    }

    /**
     * @dev Internal function to validate a new dependency. It checks the dependency is registered and not deprecated.
     * @param dependency New dependency to be set
     * @return Whether the dependency is stateless or not
     */
    function _validateDependency(address dependency) private view returns (bool) {
        (bool stateless, bool deprecated, bytes32 namespace) = IRegistry(registry).implementationData(dependency);
        require(namespace != bytes32(0), 'DEPENDENCY_NOT_REGISTERED');
        require(!deprecated, 'DEPENDENCY_DEPRECATED');
        return stateless;
    }
}