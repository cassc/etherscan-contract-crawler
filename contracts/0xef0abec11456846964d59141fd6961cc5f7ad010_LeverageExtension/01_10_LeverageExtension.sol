/*
    Copyright 2022 Set Labs Inc.

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
pragma experimental "ABIEncoderV2";

import {ISetToken} from "@setprotocol/set-protocol-v2/contracts/interfaces/ISetToken.sol";
import {IWETH} from "@setprotocol/set-protocol-v2/contracts/interfaces/external/IWETH.sol";
import {ILeverageModule} from "../../interfaces/ILeverageModule.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {BaseGlobalExtension} from "../lib/BaseGlobalExtension.sol";
import {IDelegatedManager} from "../interfaces/IDelegatedManager.sol";
import {IManagerCore} from "../interfaces/IManagerCore.sol";

/**
 * @title WrapExtension
 * @author Set Protocol
 *
 
 */
contract LeverageExtension is BaseGlobalExtension {
    /* ============ Events ============ */

    event LeverageExtensionInitialized(
        address indexed _setToken,
        address indexed _delegatedManager
    );

    /* ============ State Variables ============ */

    // Instance of LeverageModule
    ILeverageModule public immutable leverageModule;

    /* ============ Constructor ============ */

    /**
     * Instantiate with ManagerCore address and LeverageModule address.
     *
     * @param _managerCore              Address of ManagerCore contract
     * @param _leverageModule               Address of leverageModule contract
     */
    constructor(IManagerCore _managerCore, ILeverageModule _leverageModule)
        public
        BaseGlobalExtension(_managerCore)
    {
        leverageModule = _leverageModule;
    }

    /* ============ External Functions ============ */

    /**
     * ONLY OWNER: Initializes LeverageModule on the SetToken associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the LeverageModule for
     */
    function initializeModule(
        IDelegatedManager _delegatedManager,
        IERC20[] memory _collateralAssets,
        IERC20[] memory _borrowAssets
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        _initializeModule(
            _delegatedManager.setToken(),
            _delegatedManager,
            _collateralAssets,
            _borrowAssets
        );
    }

    /**
     * ONLY OWNER: Initializes WrapExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);

        emit LeverageExtensionInitialized(
            address(setToken),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY OWNER: Initializes WrapExtension to the DelegatedManager and TradeModule to the SetToken
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(
        IDelegatedManager _delegatedManager,
        IERC20[] memory _collateralAssets,
        IERC20[] memory _borrowAssets
    ) external onlyOwnerAndValidManager(_delegatedManager) {
        ISetToken setToken = _delegatedManager.setToken();

        _initializeExtension(setToken, _delegatedManager);
        _initializeModule(
            setToken,
            _delegatedManager,
            _collateralAssets,
            _borrowAssets
        );

        emit LeverageExtensionInitialized(
            address(setToken),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY MANAGER: Remove an existing SetToken and DelegatedManager tracked by the WrapExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        ISetToken setToken = delegatedManager.setToken();

        _removeExtension(setToken, delegatedManager);
    }

    function lever(
        ISetToken _setToken,
        IERC20 _borrowAsset,
        IERC20 _collateralAsset,
        uint256 _borrowQuantityUnits,
        uint256 _minReceiveQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.lever.selector,
            _setToken,
            _borrowAsset,
            _collateralAsset,
            _borrowQuantityUnits,
            _minReceiveQuantityUnits,
            _tradeAdapterName,
            _tradeData
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    function delever(
        ISetToken _setToken,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        uint256 _minRepayQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.delever.selector,
            _setToken,
            _collateralAsset,
            _repayAsset,
            _redeemQuantityUnits,
            _minRepayQuantityUnits,
            _tradeAdapterName,
            _tradeData
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    function deleverToZeroBorrowBalance(
        ISetToken _setToken,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.deleverToZeroBorrowBalance.selector,
            _setToken,
            _collateralAsset,
            _repayAsset,
            _redeemQuantityUnits,
            _tradeAdapterName,
            _tradeData
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    function addCollateralAssets(
        ISetToken _setToken,
        IERC20[] memory _newCollateralAssets
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.addCollateralAssets.selector,
            _setToken,
            _newCollateralAssets
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    function removeCollateralAssets(
        ISetToken _setToken,
        IERC20[] memory _collateralAssets
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.removeCollateralAssets.selector,
            _setToken,
            _collateralAssets
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    function addBorrowAssets(
        ISetToken _setToken,
        IERC20[] memory _newBorrowAssets
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.addBorrowAssets.selector,
            _setToken,
            _newBorrowAssets
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    function removeBorrowAssets(
        ISetToken _setToken,
        IERC20[] memory _borrowAssets
    ) external onlyOperator(_setToken) {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.removeBorrowAssets.selector,
            _setToken,
            _borrowAssets
        );
        _invokeManager(_manager(_setToken), address(leverageModule), callData);
    }

    /* ============ Internal Functions ============ */

    /**
     * Internal function to initialize LeverageModule on the SetToken associated with the DelegatedManager.
     *
     * @param _setToken             Instance of the SetToken corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the LeverageModule for
     */
    function _initializeModule(
        ISetToken _setToken,
        IDelegatedManager _delegatedManager,
        IERC20[] memory _collateralAssets,
        IERC20[] memory _borrowAssets
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            ILeverageModule.initialize.selector,
            _setToken,
            _collateralAssets,
            _borrowAssets
        );
        _invokeManager(_delegatedManager, address(leverageModule), callData);
    }
}