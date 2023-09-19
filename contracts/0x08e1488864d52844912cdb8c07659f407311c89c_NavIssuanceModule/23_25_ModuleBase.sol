/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { AddressArrayUtils } from "../../lib/AddressArrayUtils.sol";
import { ExplicitERC20 } from "../../lib/ExplicitERC20.sol";
import { IController } from "../../interfaces/IController.sol";
import { IModule } from "../../interfaces/IModule.sol";
import { IJasperVault } from "../../interfaces/IJasperVault.sol";
import { Invoke } from "./Invoke.sol";
import { Position } from "./Position.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { ResourceIdentifier } from "./ResourceIdentifier.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title ModuleBase
 * @author Set Protocol
 *
 * Abstract class that houses common Module-related state and functions.
 *
 * CHANGELOG:
 * - 4/21/21: Delegated modifier logic to internal helpers to reduce contract size
 *
 */
abstract contract ModuleBase is IModule {
    using AddressArrayUtils for address[];
    using Invoke for IJasperVault;
    using Position for IJasperVault;
    using PreciseUnitMath for uint256;
    using ResourceIdentifier for IController;
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    /* ============ State Variables ============ */

    // Address of the controller
    IController public controller;

    /* ============ Modifiers ============ */

    modifier onlyManagerAndValidSet(IJasperVault _jasperVault) {
        _validateOnlyManagerAndValidSet(_jasperVault);
        _;
    }

    modifier onlySetManager(IJasperVault _jasperVault, address _caller) {
        _validateOnlySetManager(_jasperVault, _caller);
        _;
    }

    modifier onlyValidAndInitializedSet(IJasperVault _jasperVault) {
        _validateOnlyValidAndInitializedSet(_jasperVault);
        _;
    }

    /**
     * Throws if the sender is not a JasperVault's module or module not enabled
     */
    modifier onlyModule(IJasperVault _jasperVault) {
        _validateOnlyModule(_jasperVault);
        _;
    }

    /**
     * Utilized during module initializations to check that the module is in pending state
     * and that the JasperVault is valid
     */
    modifier onlyValidAndPendingSet(IJasperVault _jasperVault) {
        _validateOnlyValidAndPendingSet(_jasperVault);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Set state variables and map asset pairs to their oracles
     *
     * @param _controller             Address of controller contract
     */
    constructor(IController _controller) public {
        controller = _controller;
    }

    /* ============ Internal Functions ============ */

    /**
     * Transfers tokens from an address (that has set allowance on the module).
     *
     * @param  _token          The address of the ERC20 token
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     * @param  _quantity       The number of tokens to transfer
     */
    function transferFrom(IERC20 _token, address _from, address _to, uint256 _quantity) internal {
        ExplicitERC20.transferFrom(_token, _from, _to, _quantity);
    }

    /**
     * Gets the integration for the module with the passed in name. Validates that the address is not empty
     */
    function getAndValidateAdapter(string memory _integrationName) internal view returns(address) {
        bytes32 integrationHash = getNameHash(_integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * Gets the integration for the module with the passed in hash. Validates that the address is not empty
     */
    function getAndValidateAdapterWithHash(bytes32 _integrationHash) internal view returns(address) {
        address adapter = controller.getIntegrationRegistry().getIntegrationAdapterWithHash(
            address(this),
            _integrationHash
        );

        require(adapter != address(0), "Must be valid adapter");
        return adapter;
    }

    /**
     * Gets the total fee for this module of the passed in index (fee % * quantity)
     */
    function getModuleFee(uint256 _feeIndex, uint256 _quantity) internal view returns(uint256) {
        uint256 feePercentage = controller.getModuleFee(address(this), _feeIndex);
        return _quantity.preciseMul(feePercentage);
    }

    /**
     * Pays the _feeQuantity from the _jasperVault denominated in _token to the protocol fee recipient
     */
    function payProtocolFeeFromSetToken(IJasperVault _jasperVault, address _token, uint256 _feeQuantity) internal {
        if (_feeQuantity > 0) {
            _jasperVault.strictInvokeTransfer(_token, controller.feeRecipient(), _feeQuantity);
        }
    }

    /**
     * Returns true if the module is in process of initialization on the JasperVault
     */
    function isSetPendingInitialization(IJasperVault _jasperVault) internal view returns(bool) {
        return _jasperVault.isPendingModule(address(this));
    }

    /**
     * Returns true if the address is the JasperVault's manager
     */
    function isSetManager(IJasperVault _jasperVault, address _toCheck) internal view returns(bool) {
        return _jasperVault.manager() == _toCheck;
    }

    /**
     * Returns true if JasperVault must be enabled on the controller
     * and module is registered on the JasperVault
     */
    function isSetValidAndInitialized(IJasperVault _jasperVault) internal view returns(bool) {
        return controller.isSet(address(_jasperVault)) &&
            _jasperVault.isInitializedModule(address(this));
    }

    /**
     * Hashes the string and returns a bytes32 value
     */
    function getNameHash(string memory _name) internal pure returns(bytes32) {
        return keccak256(bytes(_name));
    }

    /* ============== Modifier Helpers ===============
     * Internal functions used to reduce bytecode size
     */

    /**
     * Caller must JasperVault manager and JasperVault must be valid and initialized
     */
    function _validateOnlyManagerAndValidSet(IJasperVault _jasperVault) internal view {
       require(isSetManager(_jasperVault, msg.sender), "Must be the JasperVault manager");
       require(isSetValidAndInitialized(_jasperVault), "Must be a valid and initialized JasperVault");
    }

    /**
     * Caller must JasperVault manager
     */
    function _validateOnlySetManager(IJasperVault _jasperVault, address _caller) internal view {
        require(isSetManager(_jasperVault, _caller), "Must be the JasperVault manager");
    }

    /**
     * JasperVault must be valid and initialized
     */
    function _validateOnlyValidAndInitializedSet(IJasperVault _jasperVault) internal view {
        require(isSetValidAndInitialized(_jasperVault), "Must be a valid and initialized JasperVault");
    }

    /**
     * Caller must be initialized module and module must be enabled on the controller
     */
    function _validateOnlyModule(IJasperVault _jasperVault) internal view {
        require(
            _jasperVault.moduleStates(msg.sender) == IJasperVault.ModuleState.INITIALIZED,
            "Only the module can call"
        );

        require(
            controller.isModule(msg.sender),
            "Module must be enabled on controller"
        );
    }

    /**
     * JasperVault must be in a pending state and module must be in pending state
     */
    function _validateOnlyValidAndPendingSet(IJasperVault _jasperVault) internal view {
        require(controller.isSet(address(_jasperVault)), "Must be controller-enabled JasperVault");
        require(isSetPendingInitialization(_jasperVault), "Must be pending initialization");
    }
}