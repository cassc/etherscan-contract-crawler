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

import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vault/contracts/ISmartVaultsFactory.sol';
import '@mimic-fi/v2-helpers/contracts/auth/IAuthorizer.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';

import '../actions/ReceiverAction.sol';
import '../actions/RelayedAction.sol';
import '../actions/TimeLockedAction.sol';
import '../actions/TokenThresholdAction.sol';
import '../actions/WithdrawalAction.sol';
import '../permissions/PermissionsManager.sol';
import '../permissions/PermissionsHelpers.sol';

/**
 * @title Deployer
 * @dev Deployer library offering a bunch of set-up methods to deploy and customize smart vaults
 */
library Deployer {
    using UncheckedMath for uint256;
    using PermissionsHelpers for PermissionsManager;

    // Namespace to use by this deployer to fetch ISmartVaultFactory implementations from the Mimic Registry
    bytes32 private constant SMART_VAULT_FACTORY_NAMESPACE = keccak256('SMART_VAULTS_FACTORY');

    // Namespace to use by this deployer to fetch ISmartVault implementations from the Mimic Registry
    bytes32 private constant SMART_VAULT_NAMESPACE = keccak256('SMART_VAULT');

    // Namespace to use by this deployer to fetch IStrategy implementations from the Mimic Registry
    bytes32 private constant STRATEGY_NAMESPACE = keccak256('STRATEGY');

    // Namespace to use by this deployer to fetch IPriceOracle implementations from the Mimic Registry
    bytes32 private constant PRICE_ORACLE_NAMESPACE = keccak256('PRICE_ORACLE');

    // Namespace to use by this deployer to fetch ISwapConnector implementations from the Mimic Registry
    bytes32 private constant SWAP_CONNECTOR_NAMESPACE = keccak256('SWAP_CONNECTOR');

    // Namespace to use by this deployer to fetch IBridgeConnector implementations from the Mimic Registry
    bytes32 private constant BRIDGE_CONNECTOR_NAMESPACE = keccak256('BRIDGE_CONNECTOR');

    /**
     * @dev Smart vault params
     * @param factory Address of the factory that will be used to deploy an instance of the Smart Vault implementation
     * @param impl Address of the Smart Vault implementation to be used
     * @param salt Salt bytes to derivate the address of the new Smart Vault instance
     * @param admin Address that will be granted with admin rights for the deployed Smart Vault
     * @param bridgeConnector Optional Bridge Connector to set for the Smart Vault
     * @param swapConnector Optional Swap Connector to set for the Smart Vault
     * @param strategies List of strategies to be allowed for the Smart Vault
     * @param priceOracle Optional Price Oracle to set for the Smart Vault
     * @param priceFeedParams List of price feeds to be set for the Smart Vault
     * @param feeCollector Address to be set as the fee collector
     * @param swapFee Swap fee params
     * @param bridgeFee Bridge fee params
     * @param withdrawFee Withdraw fee params
     * @param performanceFee Performance fee params
     */
    struct SmartVaultParams {
        address factory;
        address impl;
        bytes32 salt;
        address admin;
        address[] strategies;
        address bridgeConnector;
        address swapConnector;
        address priceOracle;
        PriceFeedParams[] priceFeedParams;
        address feeCollector;
        address feeCollectorAdmin;
        SmartVaultFeeParams swapFee;
        SmartVaultFeeParams bridgeFee;
        SmartVaultFeeParams withdrawFee;
        SmartVaultFeeParams performanceFee;
    }

    /**
     * @dev Smart Vault price feed params
     * @param base Base token of the price feed
     * @param quote Quote token of the price feed
     * @param feed Address of the price feed
     */
    struct PriceFeedParams {
        address base;
        address quote;
        address feed;
    }

    /**
     * @dev Smart Vault fee configuration parameters
     * @param pct Percentage expressed using 16 decimals (1e18 = 100%)
     * @param cap Maximum amount of fees to be charged per period
     * @param token Address of the token to express the cap amount
     * @param period Period length in seconds
     */
    struct SmartVaultFeeParams {
        uint256 pct;
        uint256 cap;
        address token;
        uint256 period;
    }

    /**
     * @dev Relayed action params
     * @param relayers List of addresses to be marked as allowed executors and in particular as authorized relayers
     * @param gasPriceLimit Gas price limit to be used for the relayed action
     * @param txCostLimit Total transaction cost limit to be used for the relayed action
     */
    struct RelayedActionParams {
        address[] relayers;
        uint256 gasPriceLimit;
        uint256 txCostLimit;
    }

    /**
     * @dev Token threshold action params
     * @param token Address of the token of the threshold
     * @param amount Amount of tokens of the threshold
     */
    struct TokenThresholdActionParams {
        address token;
        uint256 amount;
    }

    /**
     * @dev Time-locked action params
     * @param period Period in seconds to be set for the time lock
     */
    struct TimeLockedActionParams {
        uint256 period;
    }

    /**
     * @dev Withdrawal action params
     * @param recipient Address that will receive the funds from the withdraw action
     */
    struct WithdrawalActionParams {
        address recipient;
    }

    /**
     * @dev Transfer Permission Manager control to a list of owners
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param owners Addresses that will be able to call the permission manager
     */
    function transferPermissionManagerControl(PermissionsManager manager, address[] memory owners) external {
        manager.authorize(manager, owners, manager.execute.selector);
        manager.unauthorize(manager, address(this), manager.execute.selector);
    }

    /**
     * @dev Create a new Smart Vault instance
     * @param registry Address of the registry to validate the Smart Vault implementation
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param params Params to customize the Smart Vault to be deployed
     * creating the Smart Vault. Sometimes this is not desired if further customization might take in place.
     */
    function createSmartVault(IRegistry registry, PermissionsManager manager, SmartVaultParams memory params)
        external
        returns (SmartVault smartVault)
    {
        require(params.admin != address(0), 'SMART_VAULT_ADMIN_ZERO');
        require(params.feeCollectorAdmin != address(0), 'SMART_VAULT_FEE_ADMIN_ZERO');

        // Clone requested Smart Vault implementation and initialize
        require(registry.isActive(SMART_VAULT_FACTORY_NAMESPACE, params.factory), 'BAD_SMART_VAULT_FACTORY_IMPL');
        ISmartVaultsFactory factory = ISmartVaultsFactory(params.factory);

        bytes memory initializeData = abi.encodeWithSelector(SmartVault.initialize.selector, address(manager));
        bytes32 senderSalt = keccak256(abi.encodePacked(msg.sender, params.salt));
        smartVault = SmartVault(payable(factory.create(senderSalt, params.impl, initializeData)));

        // Authorize admin to perform any action except from fee collector setter
        bytes4[] memory whats = new bytes4[](19);
        whats[0] = smartVault.collect.selector;
        whats[1] = smartVault.withdraw.selector;
        whats[2] = smartVault.wrap.selector;
        whats[3] = smartVault.unwrap.selector;
        whats[4] = smartVault.claim.selector;
        whats[5] = smartVault.join.selector;
        whats[6] = smartVault.exit.selector;
        whats[7] = smartVault.swap.selector;
        whats[8] = smartVault.bridge.selector;
        whats[9] = smartVault.setStrategy.selector;
        whats[10] = smartVault.setPriceFeed.selector;
        whats[11] = smartVault.setPriceFeeds.selector;
        whats[12] = smartVault.setPriceOracle.selector;
        whats[13] = smartVault.setSwapConnector.selector;
        whats[14] = smartVault.setBridgeConnector.selector;
        whats[15] = smartVault.setWithdrawFee.selector;
        whats[16] = smartVault.setPerformanceFee.selector;
        whats[17] = smartVault.setSwapFee.selector;
        whats[18] = smartVault.setBridgeFee.selector;
        manager.authorize(smartVault, params.admin, whats);

        // Set price feeds if any
        if (params.priceFeedParams.length > 0) {
            manager.authorize(smartVault, address(this), smartVault.setPriceFeed.selector);
            for (uint256 i = 0; i < params.priceFeedParams.length; i = i.uncheckedAdd(1)) {
                PriceFeedParams memory feedParams = params.priceFeedParams[i];
                smartVault.setPriceFeed(feedParams.base, feedParams.quote, feedParams.feed);
            }
            manager.unauthorize(smartVault, address(this), smartVault.setPriceFeed.selector);
        }

        // Set price oracle if given
        if (params.priceOracle != address(0)) {
            require(registry.isActive(PRICE_ORACLE_NAMESPACE, params.priceOracle), 'BAD_PRICE_ORACLE_DEPENDENCY');
            manager.authorize(smartVault, address(this), smartVault.setPriceOracle.selector);
            smartVault.setPriceOracle(params.priceOracle);
            manager.unauthorize(smartVault, address(this), smartVault.setPriceOracle.selector);
        }

        // Set strategies if any
        if (params.strategies.length > 0) {
            manager.authorize(smartVault, address(this), smartVault.setStrategy.selector);
            for (uint256 i = 0; i < params.strategies.length; i = i.uncheckedAdd(1)) {
                require(registry.isActive(STRATEGY_NAMESPACE, params.strategies[i]), 'BAD_STRATEGY_DEPENDENCY');
                smartVault.setStrategy(params.strategies[i], true);
            }
            manager.unauthorize(smartVault, address(this), smartVault.setStrategy.selector);
        }

        // Set swap connector if given
        if (params.swapConnector != address(0)) {
            require(registry.isActive(SWAP_CONNECTOR_NAMESPACE, params.swapConnector), 'BAD_SWAP_CONNECTOR_DEPENDENCY');
            manager.authorize(smartVault, address(this), smartVault.setSwapConnector.selector);
            smartVault.setSwapConnector(params.swapConnector);
            manager.unauthorize(smartVault, address(this), smartVault.setSwapConnector.selector);
        }

        // Set bridge connector if given
        if (params.bridgeConnector != address(0)) {
            bool isActive = registry.isActive(BRIDGE_CONNECTOR_NAMESPACE, params.bridgeConnector);
            require(isActive, 'BAD_BRIDGE_CONNECTOR_DEPENDENCY');
            manager.authorize(smartVault, address(this), smartVault.setBridgeConnector.selector);
            smartVault.setBridgeConnector(params.bridgeConnector);
            manager.unauthorize(smartVault, address(this), smartVault.setBridgeConnector.selector);
        }

        // If no fee collector is given, make sure no fee amounts are requested too
        manager.authorize(smartVault, params.feeCollectorAdmin, smartVault.setFeeCollector.selector);
        if (params.feeCollector != address(0)) {
            manager.authorize(smartVault, address(this), smartVault.setFeeCollector.selector);
            smartVault.setFeeCollector(params.feeCollector);
            manager.unauthorize(smartVault, address(this), smartVault.setFeeCollector.selector);
        } else {
            bool noFees = params.withdrawFee.pct == 0 &&
                params.swapFee.pct == 0 &&
                params.bridgeFee.pct == 0 &&
                params.performanceFee.pct == 0;
            require(noFees, 'SMART_VAULT_FEES_NO_COLLECTOR');
        }

        // Set withdraw fee if not zero
        SmartVaultFeeParams memory withdrawFee = params.withdrawFee;
        if (withdrawFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setWithdrawFee.selector);
            smartVault.setWithdrawFee(withdrawFee.pct, withdrawFee.cap, withdrawFee.token, withdrawFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setWithdrawFee.selector);
        }

        // Set swap fee if not zero
        SmartVaultFeeParams memory swapFee = params.swapFee;
        if (swapFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setSwapFee.selector);
            smartVault.setSwapFee(swapFee.pct, swapFee.cap, swapFee.token, swapFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setSwapFee.selector);
        }

        // Set bridge fee if not zero
        SmartVaultFeeParams memory bridgeFee = params.bridgeFee;
        if (bridgeFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setBridgeFee.selector);
            smartVault.setBridgeFee(bridgeFee.pct, bridgeFee.cap, bridgeFee.token, bridgeFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setBridgeFee.selector);
        }

        // Set performance fee if not zero
        SmartVaultFeeParams memory perfFee = params.performanceFee;
        if (perfFee.pct != 0) {
            manager.authorize(smartVault, address(this), smartVault.setPerformanceFee.selector);
            smartVault.setPerformanceFee(perfFee.pct, perfFee.cap, perfFee.token, perfFee.period);
            manager.unauthorize(smartVault, address(this), smartVault.setPerformanceFee.selector);
        }
    }

    /**
     * @dev Set up a base action
     * @param action Base action to be set up
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Base Action
     * @param smartVault Address of the Smart Vault to be set in the Base Action
     */
    function setupBaseAction(BaseAction action, PermissionsManager manager, address admin, address smartVault)
        external
    {
        require(admin != address(0), 'BASE_ACTION_ADMIN_ZERO');

        manager.authorize(action, Arrays.from(admin, address(this)), action.setSmartVault.selector);
        action.setSmartVault(smartVault);
        manager.unauthorize(action, address(this), action.setSmartVault.selector);
    }

    /**
     * @dev Set up a list of executors for a given action
     * @param action Action whose executors are being allowed
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param executors List of addresses to be allowed to call the given action
     * @param callSelector Selector of the function to allow the list of executors
     */
    function setupActionExecutors(
        BaseAction action,
        PermissionsManager manager,
        address[] memory executors,
        bytes4 callSelector
    ) external {
        manager.authorize(action, executors, callSelector);
    }

    /**
     * @dev Set up a Relayed action
     * @param action Relayed action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Relayed action
     * @param params Params to customize the Relayed action
     */
    function setupRelayedAction(
        RelayedAction action,
        PermissionsManager manager,
        address admin,
        RelayedActionParams memory params
    ) external {
        // Authorize admin to set relayers and txs limits
        require(admin != address(0), 'RELAYED_ACTION_ADMIN_ZERO');

        address[] memory whos = Arrays.from(admin, address(this));
        bytes4[] memory whats = Arrays.from(action.setLimits.selector, action.setRelayer.selector);

        manager.authorize(action, whos, whats);

        action.setLimits(params.gasPriceLimit, params.txCostLimit);
        for (uint256 i = 0; i < params.relayers.length; i = i.uncheckedAdd(1)) {
            action.setRelayer(params.relayers[i], true);
        }

        manager.unauthorize(action, address(this), whats);
    }

    /**
     * @dev Set up a Token Threshold action
     * @param action Token threshold action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Token Threshold action
     * @param params Params to customize the Token Threshold action
     */
    function setupTokenThresholdAction(
        TokenThresholdAction action,
        PermissionsManager manager,
        address admin,
        TokenThresholdActionParams memory params
    ) external {
        require(admin != address(0), 'TOKEN_THRESHOLD_ADMIN_ZERO');
        manager.authorize(action, Arrays.from(admin, address(this)), action.setThreshold.selector);
        action.setThreshold(params.token, params.amount);
        manager.unauthorize(action, address(this), action.setThreshold.selector);
    }

    /**
     * @dev Set up a Time-locked action
     * @param action Time-locked action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Time-locked action
     * @param params Params to customize the Time-locked action
     */
    function setupTimeLockedAction(
        TimeLockedAction action,
        PermissionsManager manager,
        address admin,
        TimeLockedActionParams memory params
    ) external {
        require(admin != address(0), 'TIME_LOCKED_ACTION_ADMIN_ZERO');
        manager.authorize(action, Arrays.from(admin, address(this)), action.setTimeLock.selector);
        action.setTimeLock(params.period);
        manager.unauthorize(action, address(this), action.setTimeLock.selector);
    }

    /**
     * @dev Set up a Withdrawal action
     * @param action Relayed action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Withdrawal action
     * @param params Params to customize the Withdrawal action
     */
    function setupWithdrawalAction(
        WithdrawalAction action,
        PermissionsManager manager,
        address admin,
        WithdrawalActionParams memory params
    ) external {
        require(admin != address(0), 'WITHDRAWAL_ACTION_ADMIN_ZERO');
        manager.authorize(action, Arrays.from(admin, address(this)), action.setRecipient.selector);
        action.setRecipient(params.recipient);
        manager.unauthorize(action, address(this), action.setRecipient.selector);
    }

    /**
     * @dev Set up a Receiver action
     * @param action Relayed action to be configured
     * @param manager Permissions manager that will control the entire Smart Vault and its actions
     * @param admin Address that will be granted with admin rights for the Receiver action
     */
    function setupReceiverAction(ReceiverAction action, PermissionsManager manager, address admin) external {
        require(admin != address(0), 'RECEIVER_ACTION_ADMIN_ZERO');
        manager.authorize(action, admin, action.transferToSmartVault.selector);
    }
}