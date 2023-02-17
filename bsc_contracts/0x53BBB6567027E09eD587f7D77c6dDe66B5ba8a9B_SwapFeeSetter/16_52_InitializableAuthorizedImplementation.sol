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

import './InitializableImplementation.sol';

/**
 * @title InitializableAuthorizedImplementation
 * @dev InitializableImplementation using the Authorizer mixin. Initializable implementations that want to use the
 * Authorizer permissions mechanism should inherit from this contract instead.
 */
abstract contract InitializableAuthorizedImplementation is InitializableImplementation, Authorizer {
    /**
     * @dev Creates a new InitializableAuthorizedImplementation
     * @param registry Address of the Mimic Registry
     */
    constructor(address registry) InitializableImplementation(registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Initialization function that authorizes an admin account to authorize and unauthorize accounts.
     * Note this function can only be called from a function marked with the `initializer` modifier.
     * @param admin Address to be granted authorize and unauthorize permissions
     */
    function _initialize(address admin) internal onlyInitializing {
        _initialize();
        _authorize(admin, Authorizer.authorize.selector);
        _authorize(admin, Authorizer.unauthorize.selector);
    }
}