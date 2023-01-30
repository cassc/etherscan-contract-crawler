// SPDX-License-Identifier: AGPL-3.0-only

/**
 *   DepositBox.sol - SKALE Interchain Messaging Agent
 *   Copyright (C) 2021-Present SKALE Labs
 *   @author Artem Payvin
 *   @author Dmytro Stebaiev
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

import "@skalenetwork/ima-interfaces/mainnet/IDepositBox.sol";

import "./Twin.sol";


/**
 * @title DepositBox
 * @dev Abstract contracts for DepositBoxes on mainnet.
 */
abstract contract DepositBox is IDepositBox, Twin {

    ILinker public linker;

    // schainHash => true if automatic deployment tokens on schain was enabled 
    mapping(bytes32 => bool) private _automaticDeploy;

    bytes32 public constant DEPOSIT_BOX_MANAGER_ROLE = keccak256("DEPOSIT_BOX_MANAGER_ROLE");

    /**
     * @dev Modifier for checking whether schain was not killed.
     */
    modifier whenNotKilled(bytes32 schainHash) {
        require(linker.isNotKilled(schainHash), "Schain is killed");
        _;
    }

    /**
     * @dev Modifier for checking whether schain was killed.
     */
    modifier whenKilled(bytes32 schainHash) {
        require(!linker.isNotKilled(schainHash), "Schain is not killed");
        _;
    }

    /**
     * @dev Modifier for checking whether schainName is not equal to `Mainnet` 
     * and address of receiver is not equal to null before transferring funds from mainnet to schain.
     */
    modifier rightTransaction(string memory schainName, address to) {
        require(
            keccak256(abi.encodePacked(schainName)) != keccak256(abi.encodePacked("Mainnet")),
            "SKALE chain name cannot be Mainnet"
        );
        require(to != address(0), "Receiver address cannot be null");
        _;
    }

    /**
     * @dev Modifier for checking whether schainHash is not equal to `Mainnet` 
     * and sender contract was added as contract processor on schain.
     */
    modifier checkReceiverChain(bytes32 schainHash, address sender) {
        require(
            schainHash != keccak256(abi.encodePacked("Mainnet")) &&
            sender == schainLinks[schainHash],
            "Receiver chain is incorrect"
        );
        _;
    }

    /**
     * @dev Allows Schain owner turn on whitelist of tokens.
     */
    function enableWhitelist(string memory schainName) external override onlySchainOwner(schainName) {
        _automaticDeploy[keccak256(abi.encodePacked(schainName))] = false;
    }

    /**
     * @dev Allows Schain owner turn off whitelist of tokens.
     */
    function disableWhitelist(string memory schainName) external override onlySchainOwner(schainName) {
        _automaticDeploy[keccak256(abi.encodePacked(schainName))] = true;
    }

    function initialize(
        IContractManager contractManagerOfSkaleManagerValue,
        ILinker newLinker,
        IMessageProxyForMainnet messageProxyValue
    )
        public
        override
        virtual
        initializer
    {
        Twin.initialize(contractManagerOfSkaleManagerValue, messageProxyValue);
        _setupRole(LINKER_ROLE, address(newLinker));
        linker = newLinker;
    }

    /**
     * @dev Returns is whitelist enabled on schain.
     */
    function isWhitelisted(string memory schainName) public view override returns (bool) {
        return !_automaticDeploy[keccak256(abi.encodePacked(schainName))];
    }
}