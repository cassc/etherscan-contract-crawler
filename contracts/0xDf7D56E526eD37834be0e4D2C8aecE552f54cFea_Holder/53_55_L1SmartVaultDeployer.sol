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
import './BaseSmartVaultDeployer.sol';

// solhint-disable avoid-low-level-calls

contract L1SmartVaultDeployer is BaseSmartVaultDeployer {
    using UncheckedMath for uint256;

    struct Params {
        IRegistry registry;
        Deployer.SmartVaultParams smartVaultParams;
        FunderActionParams funderActionParams;
        HolderActionParams holderActionParams;
        L1HopBridgerActionParams l1HopBridgerActionParams;
    }

    struct L1HopBridgerActionParams {
        address impl;
        address admin;
        address[] managers;
        uint256 maxDeadline;
        uint256 maxSlippage;
        uint256[] allowedChainIds;
        HopBridgeParams[] hopBridgeParams;
        HopRelayerParams[] hopRelayerParams;
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

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.smartVaultParams, false);
        _setupFunderAction(smartVault, params.funderActionParams);
        _setupHolderAction(smartVault, params.holderActionParams);
        _setupL1HopBridgerAction(smartVault, params.l1HopBridgerActionParams);
        Deployer.transferAdminPermissions(smartVault, params.smartVaultParams.admin);
    }

    function _setupL1HopBridgerAction(SmartVault smartVault, L1HopBridgerActionParams memory params) internal {
        // Create and setup action
        L1HopBridger bridger = L1HopBridger(payable(params.impl));
        Deployer.setupBaseAction(bridger, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, new address[](0));
        Deployer.setupActionExecutors(bridger, executors, bridger.call.selector);
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

        // Set bridger chain IDs
        bridger.authorize(params.admin, bridger.setAllowedChain.selector);
        bridger.authorize(address(this), bridger.setAllowedChain.selector);
        for (uint256 i = 0; i < params.allowedChainIds.length; i = i.uncheckedAdd(1)) {
            bridger.setAllowedChain(params.allowedChainIds[i], true);
        }
        bridger.unauthorize(address(this), bridger.setAllowedChain.selector);

        // Transfer admin permissions to admin
        Deployer.transferAdminPermissions(bridger, params.admin);

        // Authorize action to bridge from Smart Vault
        smartVault.authorize(address(bridger), smartVault.bridge.selector);
    }
}