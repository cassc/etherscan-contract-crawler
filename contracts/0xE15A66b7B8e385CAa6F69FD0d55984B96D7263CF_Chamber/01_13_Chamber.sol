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

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ArrayUtils} from "./lib/ArrayUtils.sol";
import {IChamberGod} from "./interfaces/IChamberGod.sol";
import {IChamber} from "./interfaces/IChamber.sol";
import {PreciseUnitMath} from "./lib/PreciseUnitMath.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Chamber is IChamber, Owned, ReentrancyGuard, ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    IChamberGod private god;

    /*//////////////////////////////////////////////////////////////
                                 LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using ArrayUtils for address[];
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    using Address for address;
    using PreciseUnitMath for uint256;

    /*//////////////////////////////////////////////////////////////
                            CHAMBER STORAGE
    //////////////////////////////////////////////////////////////*/

    address[] public constituents;

    mapping(address => uint256) public constituentQuantities;

    EnumerableSet.AddressSet private wizards;
    EnumerableSet.AddressSet private managers;
    EnumerableSet.AddressSet private allowedContracts;

    ChamberState private chamberLockState = ChamberState.UNLOCKED;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyManager() virtual {
        require(isManager(msg.sender), "Must be Manager");

        _;
    }

    modifier onlyWizard() virtual {
        require(isWizard(msg.sender), "Must be a wizard");

        _;
    }

    modifier chambersNonReentrant() virtual {
        require(chamberLockState == ChamberState.UNLOCKED, "Non reentrancy allowed");
        chamberLockState = ChamberState.LOCKED;
        _;
        chamberLockState = ChamberState.UNLOCKED;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _owner        Owner of the chamber
     * @param _name         Name of the chamber token
     * @param _symbol       Symbol of the chamber token
     * @param _constituents Initial constituents addresses of the chamber
     * @param _quantities   Initial quantities of the chamber constituents
     * @param _wizards      Allowed addresses that can access onlyWizard functions
     * @param _managers     Allowed addresses that can access onlyManager functions
     */
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address[] memory _constituents,
        uint256[] memory _quantities,
        address[] memory _wizards,
        address[] memory _managers
    ) Owned(_owner) ERC20(_name, _symbol, 18) {
        constituents = _constituents;
        god = IChamberGod(msg.sender);

        for (uint256 i = 0; i < _wizards.length; i++) {
            require(wizards.add(_wizards[i]), "Cannot add wizard");
        }

        for (uint256 i = 0; i < _managers.length; i++) {
            require(managers.add(_managers[i]), "Cannot add manager");
        }

        for (uint256 j = 0; j < _constituents.length; j++) {
            constituentQuantities[_constituents[j]] = _quantities[j];
        }
    }

    /*//////////////////////////////////////////////////////////////
                               CHAMBER MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /**
     * Allows the wizard to add a new constituent to the Chamber
     *
     * @param _constituent The address of the constituent to add
     */
    function addConstituent(address _constituent) external onlyWizard nonReentrant {
        require(!isConstituent(_constituent), "Must not be constituent");

        constituents.push(_constituent);

        emit ConstituentAdded(_constituent);
    }

    /**
     * Allows the wizard to remove a constituent from the Chamber
     *
     * @param _constituent The address of the constituent to remove
     */
    function removeConstituent(address _constituent) external onlyWizard nonReentrant {
        require(isConstituent(_constituent), "Must be constituent");

        constituents.removeStorage(_constituent);

        emit ConstituentRemoved(_constituent);
    }

    /**
     * Checks if the address is a manager of the Chamber
     *
     * @param _manager The address of a manager
     *
     * @return bool True/False if the address is a manager or not
     */
    function isManager(address _manager) public view returns (bool) {
        return managers.contains(_manager);
    }

    /**
     * Checks if the address is a wizard of the Chamber
     *
     * @param _wizard The address of a wizard
     *
     * @return bool True/False if the address is a wizard or not
     */
    function isWizard(address _wizard) public view returns (bool) {
        return wizards.contains(_wizard);
    }

    /**
     * Checks if the address is a constituent of the Chamber
     *
     * @param _constituent The address of a constituent
     *
     * @return bool True/False if the address is a constituent or not
     */
    function isConstituent(address _constituent) public view returns (bool) {
        return constituents.contains(_constituent);
    }

    /**
     * Allows the Owner to add a new manager to the Chamber
     *
     * @param _manager The address of the manager to add
     */
    function addManager(address _manager) external onlyOwner nonReentrant {
        require(!isManager(_manager), "Already manager");
        require(_manager != address(0), "Cannot add null address");

        require(managers.add(_manager), "Cannot add manager");

        emit ManagerAdded(_manager);
    }

    /**
     * Allows the Owner to remove a manager from the Chamber
     *
     * @param _manager The address of the manager to remove
     */
    function removeManager(address _manager) external onlyOwner nonReentrant {
        require(isManager(_manager), "Not a manager");

        require(managers.remove(_manager), "Cannot remove manager");

        emit ManagerRemoved(_manager);
    }

    /**
     * Allows a Manager to add a new wizard to the Chamber
     *
     * @param _wizard The address of the wizard to add
     */
    function addWizard(address _wizard) external onlyManager nonReentrant {
        require(god.isWizard(_wizard), "Wizard not validated in ChamberGod");
        require(!isWizard(_wizard), "Wizard already in Chamber");

        require(wizards.add(_wizard), "Cannot add wizard");

        emit WizardAdded(_wizard);
    }

    /**
     * Allows a Manager to remove a wizard from the Chamber
     *
     * @param _wizard The address of the wizard to remove
     */
    function removeWizard(address _wizard) external onlyManager nonReentrant {
        require(isWizard(_wizard), "Wizard not in chamber");

        require(wizards.remove(_wizard), "Cannot remove wizard");

        emit WizardRemoved(_wizard);
    }

    /**
     * Returns an array with the addresses of all the constituents of the
     * Chamber
     *
     * @return an array of addresses for the constituents
     */
    function getConstituentsAddresses() external view returns (address[] memory) {
        return constituents;
    }

    /**
     * Returns an array with the quantities of all the constituents of the
     * Chamber
     *
     * @return an array of uint256 for the quantities of the constituents
     */
    function getQuantities() external view returns (uint256[] memory) {
        uint256[] memory quantities = new uint256[](constituents.length);
        for (uint256 i = 0; i < constituents.length; i++) {
            quantities[i] = constituentQuantities[constituents[i]];
        }

        return quantities;
    }

    /**
     * Returns the quantity of a constituent of the Chamber
     *
     * @param _constituent The address of the constituent
     *
     * @return uint256 The quantity of the constituent
     */
    function getConstituentQuantity(address _constituent) external view returns (uint256) {
        return constituentQuantities[_constituent];
    }

    /**
     * Returns the addresses of all the wizards of the Chamber
     *
     * @return address[] Array containing the addresses of the wizards of the Chamber
     */
    function getWizards() external view returns (address[] memory) {
        return wizards.values();
    }

    /**
     * Returns the addresses of all the managers of the Chamber
     *
     * @return address[] Array containing the addresses of the managers of the Chamber
     */
    function getManagers() external view returns (address[] memory) {
        return managers.values();
    }

    /**
     * Returns the addresses of all the allowedContracts of the Chamber
     *
     * @return address[] Array containing the addresses of the allowedContracts of the Chamber
     */
    function getAllowedContracts() external view returns (address[] memory) {
        return allowedContracts.values();
    }

    /**
     * Allows a Manager to add a new allowedContract to the Chamber
     *
     * @param _target The address of the allowedContract to add
     */
    function addAllowedContract(address _target) external onlyManager nonReentrant {
        require(god.isAllowedContract(_target), "Contract not allowed in ChamberGod");
        require(!isAllowedContract(_target), "Contract already allowed");

        require(allowedContracts.add(_target), "Cannot add contract");

        emit AllowedContractAdded(_target);
    }

    /**
     * Allows a Manager to remove an allowedContract from the Chamber
     *
     * @param _target The address of the allowedContract to remove
     */
    function removeAllowedContract(address _target) external onlyManager nonReentrant {
        require(isAllowedContract(_target), "Contract not allowed");

        require(allowedContracts.remove(_target), "Cannot remove contract");

        emit AllowedContractRemoved(_target);
    }

    /**
     * Checks if the address is an allowedContract of the Chamber
     *
     * @param _target The address of an allowedContract
     *
     * @return bool True/False if the address is an allowedContract or not
     */
    function isAllowedContract(address _target) public view returns (bool) {
        return allowedContracts.contains(_target);
    }

    /*//////////////////////////////////////////////////////////////
                               CHAMBER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Allows a wizard to mint an specific amount of chamber tokens
     * to a recipient
     *
     * @param _recipient   The address of the recipient
     * @param _quantity    The quantity of the chamber to mint
     */
    function mint(address _recipient, uint256 _quantity) external onlyWizard nonReentrant {
        _mint(_recipient, _quantity);
    }

    /**
     * Allows a wizard to burn an specific amount of chamber tokens
     * from a source
     *
     * @param _from          The address of the source to burn from
     * @param _quantity      The quantity of the chamber tokens to burn
     */
    function burn(address _from, uint256 _quantity) external onlyWizard nonReentrant {
        _burn(_from, _quantity);
    }

    /**
     * Locks the chamber from potentially malicious outside calls of contracts
     * that were not created by arch-protocol
     */
    function lockChamber() external onlyWizard nonReentrant {
        require(chamberLockState == ChamberState.UNLOCKED, "Chamber locked");
        chamberLockState = ChamberState.LOCKED;
    }

    /**
     * Unlocks the chamber from potentially malicious outside calls of contracts
     * that were not created by arch-protocol
     */
    function unlockChamber() external onlyWizard nonReentrant {
        require(chamberLockState == ChamberState.LOCKED, "Chamber already unlocked");
        chamberLockState = ChamberState.UNLOCKED;
    }

    /**
     * Allows a wizard to transfer an specific amount of constituent tokens
     * to a recipient
     *
     * @param _constituent   The address of the constituent
     * @param _recipient     The address of the recipient to transfer tokens to
     * @param _quantity      The quantity of the constituent to transfer
     */
    function withdrawTo(address _constituent, address _recipient, uint256 _quantity)
        external
        onlyWizard
        nonReentrant
    {
        if (_quantity > 0) {
            // Retrieve current balance of token for the vault
            uint256 existingVaultBalance = IERC20(_constituent).balanceOf(address(this));

            // Call specified ERC20 token contract to transfer tokens from Vault to user
            IERC20(_constituent).safeTransfer(_recipient, _quantity);

            // Verify transfer quantity is reflected in balance
            uint256 newVaultBalance = IERC20(_constituent).balanceOf(address(this));

            // Check to make sure current balances are as expected
            require(
                newVaultBalance >= existingVaultBalance - _quantity,
                "Chamber.withdrawTo: Invalid post-withdraw balance"
            );
        }
    }

    /**
     * Update the quantities of the constituents in the chamber based on the
     * total suppply of tokens. Only considers constituents in the constituents
     * list. Used by wizards. E.g. after an uncollateralized mint in the streaming fee wizard .
     *
     */
    function updateQuantities() external onlyWizard nonReentrant chambersNonReentrant {
        for (uint256 i = 0; i < constituents.length; i++) {
            address _constituent = constituents[i];
            uint256 currentBalance = IERC20(_constituent).balanceOf(address(this));
            uint256 _newQuantity = currentBalance.preciseDiv(totalSupply, decimals);

            require(_newQuantity > 0, "Zero quantity not allowed");

            constituentQuantities[_constituent] = _newQuantity;
        }
    }

    /**
     * Allows wizards to make low level calls to contracts that have been
     * added to the allowedContracts mapping.
     *
     * @param _sellToken          The address of the token to sell
     * @param _sellQuantity       The amount of sellToken to sell
     * @param _buyToken           The address of the token to buy
     * @param _minBuyQuantity     The minimum amount of buyToken that should be bought
     * @param _data               The data to be passed to the contract
     * @param _target            The address of the contract to call
     * @param _allowanceTarget    The address of the contract to give allowance of tokens
     *
     * @return tokenAmountBought  The amount of buyToken bought
     */
    function executeTrade(
        address _sellToken,
        uint256 _sellQuantity,
        address _buyToken,
        uint256 _minBuyQuantity,
        bytes memory _data,
        address payable _target,
        address _allowanceTarget
    ) external onlyWizard nonReentrant returns (uint256 tokenAmountBought) {
        require(_target != address(this), "Cannot invoke the Chamber");
        require(isAllowedContract(_target), "Target not allowed");
        uint256 tokenAmountBefore = IERC20(_buyToken).balanceOf(address(this));
        uint256 currentAllowance = IERC20(_sellToken).allowance(address(this), _allowanceTarget);

        if (currentAllowance < _sellQuantity) {
            IERC20(_sellToken).safeIncreaseAllowance(
                _allowanceTarget, (_sellQuantity - currentAllowance)
            );
        }
        _invokeContract(_data, _target);

        currentAllowance = IERC20(_sellToken).allowance(address(this), _allowanceTarget);
        IERC20(_sellToken).safeDecreaseAllowance(_allowanceTarget, currentAllowance);

        uint256 tokenAmountAfter = IERC20(_buyToken).balanceOf(address(this));
        tokenAmountBought = tokenAmountAfter - tokenAmountBefore;
        require(tokenAmountBought >= _minBuyQuantity, "Underbought buy quantity");

        return tokenAmountBought;
    }

    /**
     * Low level call to a contract. Only allowed contracts can be called.
     *
     * @param _data           The encoded calldata to be passed to the contract
     * @param _target         The address of the contract to call
     *
     * @return response       The response bytes from the contract call
     */
    function _invokeContract(bytes memory _data, address payable _target)
        internal
        returns (bytes memory response)
    {
        response = address(_target).functionCall(_data);
        require(response.length > 0, "Low level functionCall failed");
        return (response);
    }
}