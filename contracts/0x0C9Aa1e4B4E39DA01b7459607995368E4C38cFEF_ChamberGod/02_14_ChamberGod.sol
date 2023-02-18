/**
 *     SPDX-License-Identifier: Apache License 2.0
 *
 *     Copyright 2018 Set Labs Inc.
 *     Copyright 2022 Smash Works Inc.
 *
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 *     NOTICE
 *
 *     This is a modified code from Set Labs Inc. found at
 *
 *     https://github.com/SetProtocol/set-protocol-contracts
 *
 *     All changes made by Smash Works Inc. are described and documented at
 *
 *     https://docs.arch.finance/chambers
 *
 *
 *             %@@@@@
 *          @@@@@@@@@@@
 *        #@@@@@     @@@           @@                   @@
 *       @@@@@@       @@@         @@@@                  @@
 *      @@@@@@         @@        @@  @@    @@@@@ @@@@@  @@@*@@
 *     [email protected]@@@@          @@@      @@@@@@@@   @@    @@     @@  @@
 *     @@@@@(       (((((      @@@    @@@  @@    @@@@@  @@  @@
 *    @@@@@@   (((((((
 *    @@@@@#(((((((
 *    @@@@@(((((
 *      @@@((
 */
pragma solidity ^0.8.17.0;

import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ArrayUtils} from "./lib/ArrayUtils.sol";
import {Chamber} from "./Chamber.sol";
import {IChamberGod} from "./interfaces/IChamberGod.sol";

contract ChamberGod is IChamberGod, Owned, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ArrayUtils for address[];
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                              GOD STORAGE
    //////////////////////////////////////////////////////////////*/

    EnumerableSet.AddressSet private chambers;
    EnumerableSet.AddressSet private wizards;
    EnumerableSet.AddressSet private allowedContracts;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() Owned(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                            CHAMBER GOD LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Creates a new Chamber and adds it to the list of chambers
     *
     * @param _name             A string with the name
     * @param _symbol           A string with the symbol
     * @param _constituents     An address array containing the constituents
     * @param _quantities       A uint256 array containing the quantities
     * @param _wizards          An address array containing the wizards
     * @param _managers         An address array containing the managers
     *
     * @return address          Address of the new Chamber
     */
    function createChamber(
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) external nonReentrant returns (address) {
        require(_constituents.length > 0, "Must have constituents");
        require(_constituents.length == _quantities.length, "Elements lengths not equal");
        require(!_constituents.hasDuplicate(), "Constituents must be unique");

        for (uint256 k = 0; k < _wizards.length; k++) {
            require(isWizard(_wizards[k]), "Wizard not valid");
        }

        for (uint256 j = 0; j < _constituents.length; j++) {
            require(_constituents[j] != address(0), "Constituent must not be null");
            require(_quantities[j] > 0, "Quantity must be greater than 0");
        }

        for (uint256 i = 0; i < _managers.length; i++) {
            require(_managers[i] != address(0), "Manager must not be null");
        }

        Chamber chamber = new Chamber(
          msg.sender,
          _name,
          _symbol,
          _constituents,
          _quantities,
          _wizards,
          _managers
        );

        require(chambers.add(address(chamber)), "Cannot add chamber");

        emit ChamberCreated(address(chamber), msg.sender, _name, _symbol);

        return address(chamber);
    }

    /**
     * Returns the Wizards that are approved in the ChamberGod
     *
     * @return address[]      An address array containing the Wizards
     */
    function getWizards() external view returns (address[] memory) {
        return wizards.values();
    }

    /**
     * Returns the Chambers that have been created using the ChamberGod
     *
     * @return address[]      An address array containing the Chambers
     */
    function getChambers() external view returns (address[] memory) {
        return chambers.values();
    }

    /**
     * Checks if the address is a Wizard validated in ChamberGod
     *
     * @param _wizard    The address to check
     *
     * @return bool      True if the address is a Wizard validated
     */
    function isWizard(address _wizard) public view returns (bool) {
        return wizards.contains(_wizard);
    }

    /**
     * Checks if the address is a Chamber created by ChamberGod
     *
     * @param _chamber   The address to check
     *
     * @return bool      True if the address is a Chamber created by ChamberGod
     */
    function isChamber(address _chamber) public view returns (bool) {
        return chambers.contains(_chamber);
    }

    /**
     * Allows the owner to add a new Wizard to the ChamberGod
     *
     * @param _wizard    The address of the Wizard to add
     */
    function addWizard(address _wizard) external onlyOwner nonReentrant {
        require(_wizard != address(0), "Must be a valid wizard");
        require(!isWizard(address(_wizard)), "Wizard already in ChamberGod");

        require(wizards.add(_wizard), "Cannot add wizard");

        emit WizardAdded(_wizard);
    }

    /**
     * Allows the owner to remove a Wizard from the ChamberGod
     *
     * @param _wizard    The address of the Wizard to remove
     */
    function removeWizard(address _wizard) external onlyOwner nonReentrant {
        require(isWizard(_wizard), "Wizard not valid");

        require(wizards.remove(_wizard), "Cannot remove wizard");

        emit WizardRemoved(_wizard);
    }

    /**
     * Returns the allowed contracts validated in the ChamberGod
     *
     * @return address[]      An address array containing the allowed contracts
     */
    function getAllowedContracts() external view returns (address[] memory) {
        return allowedContracts.values();
    }

    /**
     * Allows the owner to add a new allowed contract to the ChamberGod
     *
     * @param _target    The address of the allowed contract to add
     */
    function addAllowedContract(address _target) external onlyOwner nonReentrant {
        require(!isAllowedContract(_target), "Contract already allowed");

        require(allowedContracts.add(_target), "Cannot add contract");

        emit AllowedContractAdded(_target);
    }

    /**
     * Allows the owner to remove an allowed contract from the ChamberGod
     *
     * @param _target    The address of the allowed contract to remove
     */
    function removeAllowedContract(address _target) external onlyOwner nonReentrant {
        require(isAllowedContract(_target), "Contract not allowed");

        require(allowedContracts.remove(_target), "Cannot remove contract");

        emit AllowedContractRemoved(_target);
    }

    /**
     * Checks if the address is an allowed contract validated in ChamberGod
     *
     * @param _target    The address to check
     *
     * @return bool      True if the address is an allowed contract validated
     */
    function isAllowedContract(address _target) public view returns (bool) {
        return allowedContracts.contains(_target);
    }
}