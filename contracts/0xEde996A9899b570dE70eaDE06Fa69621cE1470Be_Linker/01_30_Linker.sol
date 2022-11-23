// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Linker.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *
 *   SKALE IMA is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published
 *   by the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   SKALE IMA is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with SKALE IMA.  If not, see <https://www.gnu.org/licenses/>.
 */

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@skalenetwork/ima-interfaces/mainnet/ILinker.sol";

import "../Messages.sol";
import "./MessageProxyForMainnet.sol";
import "./Twin.sol";


/**
 * @title Linker For Mainnet
 * @dev Runs on Mainnet,
 * links contracts on mainnet with their twin on schain,
 * allows to kill schain when interchain connection was not enabled.
 */
contract Linker is Twin, ILinker {
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    enum KillProcess {NotKilled, PartiallyKilledBySchainOwner, PartiallyKilledByContractOwner, Killed}
    EnumerableSetUpgradeable.AddressSet private _mainnetContracts;

    // Deprecated variable
    mapping(bytes32 => bool) private _interchainConnections;
    //

    // schainHash => schain status of killing process 
    mapping(bytes32 => KillProcess) public statuses;

    /**
     * @dev Modifier to make a function callable only if caller is granted with {LINKER_ROLE}.
     */
    modifier onlyLinker() {
        require(hasRole(LINKER_ROLE, msg.sender), "Linker role is required");
        _;
    }

    /**
     * @dev Allows Linker to register external mainnet contracts.
     * 
     * Requirements:
     * 
     * - Contract must be not registered.
     */
    function registerMainnetContract(address newMainnetContract) external override onlyLinker {
        require(_mainnetContracts.add(newMainnetContract), "The contracts was not registered");
    }

    /**
     * @dev Allows Linker to remove external mainnet contracts.
     * 
     * Requirements:
     * 
     * - Contract must be registered.
     */
    function removeMainnetContract(address mainnetContract) external override onlyLinker {
        require(_mainnetContracts.remove(mainnetContract), "The contract was not removed");
    }

    /**
     * @dev Allows Linker to connect mainnet contracts with their receivers on schain.
     * 
     * Requirements:
     * 
     * - Numbers of mainnet contracts and schain contracts must be equal.
     * - Mainnet contract must implement method `addSchainContract`.
     */
    function connectSchain(
        string calldata schainName,
        address[] calldata schainContracts
    )
        external
        override
        onlyLinker
    {
        require(schainContracts.length == _mainnetContracts.length(), "Incorrect number of addresses");
        for (uint i = 0; i < schainContracts.length; i++) {
            Twin(_mainnetContracts.at(i)).addSchainContract(schainName, schainContracts[i]);
        }
        messageProxy.addConnectedChain(schainName);
    }

    /**
     * @dev Allows Schain owner and contract deployer to kill schain. 
     * To kill the schain, both entities must call this function, and the order is not important.
     * 
     * Requirements:
     * 
     * - Interchain connection should be turned off.
     */
    function kill(string calldata schainName) override external {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        if (statuses[schainHash] == KillProcess.NotKilled) {
            if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
                statuses[schainHash] = KillProcess.PartiallyKilledByContractOwner;
            } else if (isSchainOwner(msg.sender, schainHash)) {
                statuses[schainHash] = KillProcess.PartiallyKilledBySchainOwner;
            } else {
                revert("Not allowed");
            }
        } else if (
            (
                statuses[schainHash] == KillProcess.PartiallyKilledBySchainOwner &&
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
            ) || (
                statuses[schainHash] == KillProcess.PartiallyKilledByContractOwner &&
                isSchainOwner(msg.sender, schainHash)
            )
        ) {
            statuses[schainHash] = KillProcess.Killed;
        } else {
            revert("Already killed or incorrect sender");
        }
    }

    /**
     * @dev Allows Linker disconnect schain from the network. This will remove all receiver contracts on schain.
     * Thus, messages will not go from the mainnet to the schain.
     * 
     * Requirements:
     * 
     * - Mainnet contract should implement method `removeSchainContract`.
     */
    function disconnectSchain(string calldata schainName) external override onlyLinker {
        uint length = _mainnetContracts.length();
        for (uint i = 0; i < length; i++) {
            Twin(_mainnetContracts.at(i)).removeSchainContract(schainName);
        }
        messageProxy.removeConnectedChain(schainName);
    }

    /**
     * @dev Returns true if schain is not killed.
     */
    function isNotKilled(bytes32 schainHash) external view override returns (bool) {
        return statuses[schainHash] != KillProcess.Killed;
    }

    /**
     * @dev Returns true if list of mainnet contracts has particular contract.
     */
    function hasMainnetContract(address mainnetContract) external view override returns (bool) {
        return _mainnetContracts.contains(mainnetContract);
    }

    /**
     * @dev Returns true if mainnet contracts and schain contracts are connected together for transferring messages.
     */
    function hasSchain(string calldata schainName) external view override returns (bool connected) {
        uint length = _mainnetContracts.length();
        connected = messageProxy.isConnectedChain(schainName);
        for (uint i = 0; connected && i < length; i++) {
            connected = connected && Twin(_mainnetContracts.at(i)).hasSchainContract(schainName);
        }
    }

    /**
     * @dev Create a new Linker contract.
     */
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, msg.sender);
        _setupRole(LINKER_ROLE, address(this));

        // fake usage of variable
        delete _interchainConnections[bytes32(0)];
    }
}