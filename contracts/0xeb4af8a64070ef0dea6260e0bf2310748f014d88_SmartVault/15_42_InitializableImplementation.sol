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

import './BaseImplementation.sol';

/**
 * @title InitializableImplementation
 * @dev Implementation contract to be used through proxies. Inheriting contracts are meant to be initialized through
 * initialization functions instead of constructor functions. It allows re-using the same logic contract while making
 * deployments cheaper.
 */
abstract contract InitializableImplementation is BaseImplementation, Initializable {
    /**
     * @dev Creates a new BaseImplementation. Note that initializers are disabled at creation time.
     */
    constructor(address registry) BaseImplementation(registry) {
        _disableInitializers();
    }

    /**
     * @dev Initialization function.
     * Note this function can only be called from a function marked with the `initializer` modifier.
     */
    function _initialize() internal view onlyInitializing {
        // solhint-disable-previous-line no-empty-blocks
    }
}