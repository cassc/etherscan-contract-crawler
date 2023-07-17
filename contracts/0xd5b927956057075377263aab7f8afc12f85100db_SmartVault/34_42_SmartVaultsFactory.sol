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

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v2-helpers/contracts/auth/Authorizer.sol';
import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import '@mimic-fi/v2-registry/contracts/implementations/BaseImplementation.sol';

import './ISmartVaultsFactory.sol';

/**
 * @title SmartVaultsFactory
 * @dev
 */
contract SmartVaultsFactory is ISmartVaultsFactory, BaseImplementation {
    using Address for address;

    // Smart Vaults Factory namespace
    bytes32 public constant override NAMESPACE = keccak256('SMART_VAULTS_FACTORY');

    // Namespace to use by this deployer to fetch ISmartVault implementations from the Mimic Registry
    bytes32 private constant SMART_VAULT_NAMESPACE = keccak256('SMART_VAULT');

    // List of instances' implementations indexed by instance address
    mapping (address => address) public override implementationOf;

    /**
     * @dev Creates a new Smart Vaults Factory implementation
     * @param registry Address of the Mimic Registry to be referenced
     */
    constructor(address registry) BaseImplementation(registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Creates a new Smart Vault pointing to a registered implementation using CREATE2
     * @param salt Salt bytes to derivate the address of the new instance
     * @param implementation Address of the implementation to be instanced. It must be registered and not deprecated.
     * @param initializeData Arbitrary data to be sent after deployment. It can be used to initialize the new instance.
     * @return instance Address of the new instance created
     */
    function create(bytes32 salt, address implementation, bytes memory initializeData)
        external
        override
        returns (address instance)
    {
        require(implementation != address(0), 'IMPLEMENTATION_ADDRESS_ZERO');
        require(IImplementation(implementation).NAMESPACE() == SMART_VAULT_NAMESPACE, 'BAD_IMPLEMENTATION_NAMESPACE');
        require(IRegistry(registry).isActive(SMART_VAULT_NAMESPACE, implementation), 'BAD_SMART_VAULT_IMPLEMENTATION');

        bytes32 senderSalt = keccak256(abi.encodePacked(msg.sender, salt));
        instance = Clones.cloneDeterministic(address(implementation), senderSalt);

        implementationOf[instance] = implementation;
        bytes memory result = initializeData.length == 0
            ? new bytes(0)
            : instance.functionCall(initializeData, 'SMART_VAULT_INIT_FAILED');

        emit Created(implementation, instance, result);
    }
}