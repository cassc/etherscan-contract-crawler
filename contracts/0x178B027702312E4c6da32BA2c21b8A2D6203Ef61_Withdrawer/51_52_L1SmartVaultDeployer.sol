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

import '@mimic-fi/v2-helpers/contracts/utils/Arrays.sol';
import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';

import './actions/L1HopBridger.sol';
import './actions/Withdrawer.sol';

// solhint-disable avoid-low-level-calls

contract L1SmartVaultDeployer {
    using UncheckedMath for uint256;

    struct Params {
        IRegistry registry;
        Deployer.SmartVaultParams smartVaultParams;
        L1HopBridgerActionParams l1HopBridgerActionParams;
        WithdrawerActionParams withdrawerActionParams;
    }

    struct L1HopBridgerActionParams {
        address impl;
        address admin;
        address[] managers;
        uint256 maxDeadline;
        uint256 maxSlippage;
        uint256 destinationChainId;
        HopBridgeParams[] hopBridgeParams;
        HopRelayerParams[] hopRelayerParams;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct HopBridgeParams {
        address token;
        address bridge;
    }

    struct HopRelayerParams {
        address relayer;
        uint256 maxFeePct;
    }

    struct WithdrawerActionParams {
        address impl;
        address admin;
        address[] managers;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.WithdrawalActionParams withdrawalActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.smartVaultParams, false);
        _setupL1HopBridgerAction(smartVault, params.l1HopBridgerActionParams);
        _setupWithdrawerAction(smartVault, params.withdrawerActionParams);
        Deployer.transferAdminPermissions(smartVault, params.smartVaultParams.admin);
    }

    function _setupL1HopBridgerAction(SmartVault smartVault, L1HopBridgerActionParams memory params) internal {
        // Create and setup action
        L1HopBridger bridger = L1HopBridger(payable(params.impl));
        Deployer.setupBaseAction(bridger, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(bridger, executors, bridger.call.selector);
        Deployer.setupReceiverAction(bridger, params.admin);
        Deployer.setupRelayedAction(bridger, params.admin, params.relayedActionParams);
        Deployer.setupTokenThresholdAction(bridger, params.admin, params.tokenThresholdActionParams);

        // Set bridger max deadline
        bridger.authorize(params.admin, bridger.setMaxDeadline.selector);
        bridger.authorize(address(this), bridger.setMaxDeadline.selector);
        bridger.setMaxDeadline(params.maxDeadline);
        bridger.unauthorize(address(this), bridger.setMaxDeadline.selector);

        // Set bridger max slippage
        bridger.authorize(params.admin, bridger.setMaxSlippage.selector);
        bridger.authorize(address(this), bridger.setMaxSlippage.selector);
        bridger.setMaxSlippage(params.maxSlippage);
        bridger.unauthorize(address(this), bridger.setMaxSlippage.selector);

        // Set bridger max relayer fee pcts
        bridger.authorize(params.admin, bridger.setMaxRelayerFeePct.selector);
        bridger.authorize(address(this), bridger.setMaxRelayerFeePct.selector);
        for (uint256 i = 0; i < params.hopRelayerParams.length; i = i.uncheckedAdd(1)) {
            HopRelayerParams memory hopRelayerParam = params.hopRelayerParams[i];
            bridger.setMaxRelayerFeePct(hopRelayerParam.relayer, hopRelayerParam.maxFeePct);
        }
        bridger.unauthorize(address(this), bridger.setMaxRelayerFeePct.selector);

        // Set bridger AMMs
        bridger.authorize(params.admin, bridger.setTokenBridge.selector);
        bridger.authorize(address(this), bridger.setTokenBridge.selector);
        for (uint256 i = 0; i < params.hopBridgeParams.length; i = i.uncheckedAdd(1)) {
            HopBridgeParams memory hopBridgeParam = params.hopBridgeParams[i];
            bridger.setTokenBridge(hopBridgeParam.token, hopBridgeParam.bridge);
        }
        bridger.unauthorize(address(this), bridger.setTokenBridge.selector);

        // Set bridger destination chain ID
        bridger.authorize(params.admin, bridger.setDestinationChainId.selector);
        bridger.authorize(address(this), bridger.setDestinationChainId.selector);
        bridger.setDestinationChainId(params.destinationChainId);
        bridger.unauthorize(address(this), bridger.setDestinationChainId.selector);

        // Transfer admin permissions to admin
        Deployer.transferAdminPermissions(bridger, params.admin);

        // Authorize action to bridge, and withdraw from Smart Vault
        smartVault.authorize(address(bridger), smartVault.wrap.selector);
        smartVault.authorize(address(bridger), smartVault.bridge.selector);
        smartVault.authorize(address(bridger), smartVault.withdraw.selector);
    }

    function _setupWithdrawerAction(SmartVault smartVault, WithdrawerActionParams memory params) internal {
        // Create and setup action
        Withdrawer withdrawer = Withdrawer(params.impl);
        Deployer.setupBaseAction(withdrawer, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(withdrawer, executors, withdrawer.call.selector);
        Deployer.setupRelayedAction(withdrawer, params.admin, params.relayedActionParams);
        Deployer.setupTokenThresholdAction(withdrawer, params.admin, params.tokenThresholdActionParams);
        Deployer.setupWithdrawalAction(withdrawer, params.admin, params.withdrawalActionParams);

        // Transfer admin permissions to admin
        Deployer.transferAdminPermissions(withdrawer, params.admin);

        // Authorize action to wrap and withdraw from Smart Vault
        smartVault.authorize(address(withdrawer), smartVault.wrap.selector);
        smartVault.authorize(address(withdrawer), smartVault.withdraw.selector);
    }
}