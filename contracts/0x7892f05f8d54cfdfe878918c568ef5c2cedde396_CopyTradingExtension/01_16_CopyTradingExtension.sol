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

import { IJasperVault } from "../../interfaces/IJasperVault.sol";
import {ITradeModule} from "../../interfaces/ITradeModule.sol";
import {ISignalSuscriptionModule} from "../../interfaces/ISignalSuscriptionModule.sol";

import {StringArrayUtils} from "@setprotocol/set-protocol-v2/contracts/lib/StringArrayUtils.sol";

import {BaseGlobalExtension} from "../lib/BaseGlobalExtension.sol";
import {IDelegatedManager} from "../interfaces/IDelegatedManager.sol";
import {IManagerCore} from "../interfaces/IManagerCore.sol";

/**
 * @title CopyTradingExtension
 * @author Set Protocol
 *
 * Smart contract global extension which provides DelegatedManager operator(s) the ability to execute a batch of trades
 * on a DEX and the owner the ability to restrict operator(s) permissions with an asset whitelist.
 */
contract CopyTradingExtension is BaseGlobalExtension {
    using StringArrayUtils for string[];

    /* ============ Structs ============ */

    struct TradeInfo {
        string exchangeName; // Human readable name of the exchange in the integrations registry
        address sendToken; // Address of the token to be sent to the exchange
        int256 sendQuantity; // Max units of `sendToken` sent to the exchange
        address receiveToken; // Address of the token that will be received from the exchange
        uint256 receiveQuantity; // Min units of `receiveToken` to be received from the exchange
        bool isFollower;
        bytes data; // Arbitrary bytes to be used to construct trade call data
    }

    /* ============ Events ============ */

    event IntegrationAdded(
        string _integrationName // String name of TradeModule exchange integration to allow
    );

    event IntegrationRemoved(
        string _integrationName // String name of TradeModule exchange integration to disallow
    );

    event BatchTradeExtensionInitialized(
        address indexed _jasperVault, // Address of the JasperVault which had CopyTradingExtension initialized on their manager
        address indexed _delegatedManager // Address of the DelegatedManager which initialized the CopyTradingExtension
    );

    event StringTradeFailed(
        address indexed _jasperVault, // Address of the JasperVault which the failed trade targeted
        bool indexed _isFollower, // Index of trade that failed in _trades parameter of batchTrade call
        string _reason, // String reason for the trade failure
        TradeInfo _tradeInfo // Input TradeInfo of the failed trade
    );

    event BytesTradeFailed(
        address indexed _jasperVault, // Address of the JasperVault which the failed trade targeted
        bool indexed _isFollower, // Index of trade that failed in _trades parameter of batchTrade call
        bytes _lowLevelData, // Bytes low level data reason for the trade failure
        TradeInfo _tradeInfo // Input TradeInfo of the failed trade
    );

    /* ============ State Variables ============ */

    // Instance of TradeModule
    ITradeModule public immutable tradeModule;

    ISignalSuscriptionModule public immutable signalSuscriptionModule;


    /* ============ Modifiers ============ */

    /**
     * Throws if the sender is not the ManagerCore contract owner
     */
    modifier onlyManagerCoreOwner() {
        require(
            msg.sender == managerCore.owner(),
            "Caller must be ManagerCore owner"
        );
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Instantiate with ManagerCore address, TradeModule address, and allowed TradeModule integration strings.
     *
     * @param _managerCore              Address of ManagerCore contract
     * @param _tradeModule              Address of TradeModule contract
     */
    constructor(
        IManagerCore _managerCore,
        ITradeModule _tradeModule,
        ISignalSuscriptionModule _signalSuscriptionModule
    ) public BaseGlobalExtension(_managerCore) {
        tradeModule = _tradeModule;
        signalSuscriptionModule = _signalSuscriptionModule;
    }

    /* ============ External Functions ============ */




    /**
     * ONLY OWNER: Initializes TradeModule on the JasperVault associated with the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function initializeModule(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        _initializeModule(_delegatedManager.jasperVault(), _delegatedManager);
    }

    /**
     * ONLY OWNER: Initializes CopyTradingExtension to the DelegatedManager.
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeExtension(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);

        emit BatchTradeExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY OWNER: Initializes CopyTradingExtension to the DelegatedManager and TradeModule to the JasperVault
     *
     * @param _delegatedManager     Instance of the DelegatedManager to initialize
     */
    function initializeModuleAndExtension(IDelegatedManager _delegatedManager)
        external
        onlyOwnerAndValidManager(_delegatedManager)
    {
        IJasperVault jasperVault = _delegatedManager.jasperVault();

        _initializeExtension(jasperVault, _delegatedManager);
        _initializeModule(jasperVault, _delegatedManager);

        emit BatchTradeExtensionInitialized(
            address(jasperVault),
            address(_delegatedManager)
        );
    }

    /**
     * ONLY MANAGER: Remove an existing JasperVault and DelegatedManager tracked by the CopyTradingExtension
     */
    function removeExtension() external override {
        IDelegatedManager delegatedManager = IDelegatedManager(msg.sender);
        IJasperVault jasperVault = delegatedManager.jasperVault();

        _removeExtension(jasperVault, delegatedManager);
    }

    /**
     * ONLY OPERATOR: Executes a batch of trades on a supported DEX. If any individual trades fail, events are emitted.
     * @dev Although the JasperVault units are passed in for the send and receive quantities, the total quantity
     * sent and received is the quantity of component units multiplied by the JasperVault totalSupply.
     *
     * @param _jasperVault             Instance of the JasperVault to trade
     * @param _trades               Array of TradeInfo structs containing information about trades
     */
    function batchTrade(IJasperVault _jasperVault, TradeInfo[] memory _trades)
        external
        onlyReset(_jasperVault)
        onlyOperator(_jasperVault)
    {
        _checkAdapterAndAssets(_jasperVault,_trades);
        uint256 tradesLength = _trades.length;
        for (uint256 i = 0; i < tradesLength; i++) {
            if(!ValidAdapterByModule(_jasperVault,address(tradeModule),_trades[i].exchangeName)){
               continue;
            }
            _executeTrade(_jasperVault, _trades[i]);
        }
    }

    function batchTradeWithFollowers(
        IJasperVault _jasperVault,
        TradeInfo[] memory _trades
    ) external
       onlyReset(_jasperVault)
       onlyOperator(_jasperVault) {
        _checkAdapterAndAssets(_jasperVault,_trades);
        address[] memory followers = signalSuscriptionModule.get_followers(
            address(_jasperVault)
        );
        uint256 tradesLength = _trades.length;
        for (uint256 i = 0; i < tradesLength; i++) {
            if(!ValidAdapterByModule(_jasperVault,address(tradeModule),_trades[i].exchangeName)){
               continue;
            }
            _executeTrade(_jasperVault, _trades[i]);
            for (uint256 m = 0; m < followers.length; m++) {
                TradeInfo memory newTrade = TradeInfo({
                    exchangeName: _trades[i].exchangeName,
                    sendToken: _trades[i].sendToken,
                    sendQuantity: _trades[i].sendQuantity,
                    receiveToken: _trades[i].receiveToken,
                    receiveQuantity: _trades[i].receiveQuantity,
                    data: _trades[i].data,
                    isFollower: true
                });
                _executeTrade(IJasperVault(followers[m]), newTrade);

            }
        }

        bytes memory callData = abi.encodeWithSelector(
            ISignalSuscriptionModule.exectueFollowStart.selector,
            address(_jasperVault)
        );
        _invokeManager(_manager(_jasperVault), address(signalSuscriptionModule), callData);
    }


    function _checkAdapterAndAssets(IJasperVault _jasperVault,TradeInfo[] memory _trades) internal view{
            IDelegatedManager manager = _manager(_jasperVault);
            for(uint256 i=0;i<_trades.length;i++){          
                if(_isPrimeMember(_jasperVault)){
                    require(
                        manager.isAllowedAsset(_trades[i].receiveToken),
                        "Must be allowed asset"
                    ); 
                } 
            }
        
    }

    /* ============ External Getter Functions ============ */



    /* ============ Internal Functions ============ */

    function _executeTrade(IJasperVault _jasperVault, TradeInfo memory tradeInfo)
        internal
    {
        IDelegatedManager manager = _manager(_jasperVault);
        bytes memory callData = abi.encodeWithSelector(
            ITradeModule.trade.selector,
            _jasperVault,
            tradeInfo.exchangeName,
            tradeInfo.sendToken,
            tradeInfo.sendQuantity,
            tradeInfo.receiveToken,
            tradeInfo.receiveQuantity,
            tradeInfo.data
        );
        
        // ZeroEx (for example) throws custom errors which slip through OpenZeppelin's
        // functionCallWithValue error management and surface here as `bytes`. These should be
        // decode-able off-chain given enough context about protocol targeted by the adapter.
        try
            manager.interactManager(address(tradeModule), callData)
        {} catch Error(string memory reason) {
            emit StringTradeFailed(
                address(_jasperVault),
                tradeInfo.isFollower,
                reason,
                tradeInfo
            );
        } catch (bytes memory lowLevelData) {
            emit BytesTradeFailed(
                address(_jasperVault),
                tradeInfo.isFollower,
                lowLevelData,
                tradeInfo
            );
        }
    }



    /**
     * Internal function to initialize TradeModule on the JasperVault associated with the DelegatedManager.
     *
     * @param _jasperVault             Instance of the JasperVault corresponding to the DelegatedManager
     * @param _delegatedManager     Instance of the DelegatedManager to initialize the TradeModule for
     */
    function _initializeModule(
        IJasperVault _jasperVault,
        IDelegatedManager _delegatedManager
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            ITradeModule.initialize.selector,
            _jasperVault
        );
        _invokeManager(_delegatedManager, address(tradeModule), callData);
    }
}