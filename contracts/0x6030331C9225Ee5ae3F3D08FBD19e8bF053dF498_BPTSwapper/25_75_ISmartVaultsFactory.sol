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

pragma solidity >=0.8.0;

import '@mimic-fi/v2-registry/contracts/implementations/IImplementation.sol';

/**
 * @title ISmartVaultsFactory
 * @dev Smart Vaults Factory interface, it must follow the IImplementation interface.
 */
interface ISmartVaultsFactory is IImplementation {
    /**
     * @dev Emitted every time a new Smart Vault instance is created
     */
    event Created(address indexed implementation, address indexed instance, bytes initializeResult);

    /**
     * @dev Tells the implementation associated to a contract instance
     * @param instance Address of the instance to request it's implementation
     */
    function implementationOf(address instance) external view returns (address);

    /**
     * @dev Creates a new Smart Vault pointing to a registered implementation
     * @param salt Salt bytes to derivate the address of the new instance
     * @param implementation Address of the implementation to be instanced
     * @param initializeData Arbitrary data to be sent after deployment
     * @return instance Address of the new instance created
     */
    function create(bytes32 salt, address implementation, bytes memory initializeData) external returns (address);
}