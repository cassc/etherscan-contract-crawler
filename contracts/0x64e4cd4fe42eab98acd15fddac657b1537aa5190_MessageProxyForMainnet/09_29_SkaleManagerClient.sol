// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   SkaleManagerClient.sol - SKALE Interchain Messaging Agent
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";
import "@skalenetwork/skale-manager-interfaces/ISchainsInternal.sol";
import "@skalenetwork/ima-interfaces/mainnet/ISkaleManagerClient.sol";


/**
 * @title SkaleManagerClient - contract that knows ContractManager
 * and makes calls to SkaleManager contracts.
 */
contract SkaleManagerClient is Initializable, AccessControlEnumerableUpgradeable, ISkaleManagerClient {

    IContractManager public contractManagerOfSkaleManager;

    /**
     * @dev Modifier for checking whether caller is owner of SKALE chain.
     */
    modifier onlySchainOwner(string memory schainName) {
        require(
            isSchainOwner(msg.sender, _schainHash(schainName)),
            "Sender is not an Schain owner"
        );
        _;
    }

    /**
     * @dev Modifier for checking whether caller is owner of SKALE chain.
     */
    modifier onlySchainOwnerByHash(bytes32 schainHash) {
        require(
            isSchainOwner(msg.sender, schainHash),
            "Sender is not an Schain owner"
        );
        _;
    }

    /**
     * @dev initialize - sets current address of ContractManager of SkaleManager.
     * @param newContractManagerOfSkaleManager - current address of ContractManager of SkaleManager.
     */
    function initialize(
        IContractManager newContractManagerOfSkaleManager
    )
        public
        override
        virtual
        initializer
    {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        contractManagerOfSkaleManager = newContractManagerOfSkaleManager;
    }

    /**
     * @dev Checks whether sender is owner of SKALE chain
     */
    function isSchainOwner(address sender, bytes32 schainHash) public view override returns (bool) {
        address skaleChainsInternal = contractManagerOfSkaleManager.getContract("SchainsInternal");
        return ISchainsInternal(skaleChainsInternal).isOwnerAddress(sender, schainHash);
    }

    function isAgentAuthorized(bytes32 schainHash, address sender) public view override returns (bool) {
        address skaleChainsInternal = contractManagerOfSkaleManager.getContract("SchainsInternal");
        return ISchainsInternal(skaleChainsInternal).isNodeAddressesInGroup(schainHash, sender);
    }

    function _schainHash(string memory schainName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(schainName));
    }
}