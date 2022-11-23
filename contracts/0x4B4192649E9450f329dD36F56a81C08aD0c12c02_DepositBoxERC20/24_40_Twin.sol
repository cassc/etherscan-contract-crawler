// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   Twin.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
 *   @author Vadim Yavorsky
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

import "@skalenetwork/ima-interfaces/mainnet/ITwin.sol";

import "./MessageProxyForMainnet.sol";
import "./SkaleManagerClient.sol";

/**
 * @title Twin
 * @dev Runs on Mainnet,
 * contains logic for connecting paired contracts on Mainnet and on Schain.
 */
abstract contract Twin is SkaleManagerClient, ITwin {

    IMessageProxyForMainnet public messageProxy;
    mapping(bytes32 => address) public schainLinks;
    bytes32 public constant LINKER_ROLE = keccak256("LINKER_ROLE");

    /**
     * @dev Modifier for checking whether caller is MessageProxy contract.
     */
    modifier onlyMessageProxy() {
        require(msg.sender == address(messageProxy), "Sender is not a MessageProxy");
        _;
    }

    /**
     * @dev Binds a contract on mainnet with their twin on schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or has required role.
     * - SKALE chain must not already be added.
     * - Address of contract on schain must be non-zero.
     */
    function addSchainContract(string calldata schainName, address contractReceiver) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash), "Not authorized caller"
        );
        require(schainLinks[schainHash] == address(0), "SKALE chain is already set");
        require(contractReceiver != address(0), "Incorrect address of contract receiver on Schain");
        schainLinks[schainHash] = contractReceiver;
    }

    /**
     * @dev Removes connection with contract on schain.
     *
     * Requirements:
     *
     * - `msg.sender` must be schain owner or has required role.
     * - SKALE chain must already be set.
     */
    function removeSchainContract(string calldata schainName) external override {
        bytes32 schainHash = keccak256(abi.encodePacked(schainName));
        require(
            hasRole(LINKER_ROLE, msg.sender) ||
            isSchainOwner(msg.sender, schainHash), "Not authorized caller"
        );
        require(schainLinks[schainHash] != address(0), "SKALE chain is not set");
        delete schainLinks[schainHash];
    }

    /**
     * @dev Returns true if mainnet contract and schain contract are connected together for transferring messages.
     */
    function hasSchainContract(string calldata schainName) external view override returns (bool) {
        return schainLinks[keccak256(abi.encodePacked(schainName))] != address(0);
    }
    
    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        IMessageProxyForMainnet newMessageProxy
    )
        public
        virtual
        initializer
    {
        SkaleManagerClient.initialize(contractManagerOfSkaleManagerValue);
        messageProxy = newMessageProxy;
    }
}