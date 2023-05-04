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

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsManager.sol';

import './BaseSmartVaultDeployer.sol';
import './actions/bridge/L2HopBridger.sol';
import './actions/swap/ParaswapSwapper.sol';

// solhint-disable avoid-low-level-calls

contract L2SmartVaultDeployer is BaseSmartVaultDeployer {
    using UncheckedMath for uint256;
    using PermissionsHelpers for PermissionsManager;

    struct Params {
        address[] owners;
        IRegistry registry;
        PermissionsManager manager;
        Deployer.SmartVaultParams smartVaultParams;
        SwapperActionParams paraswapSwapperActionParams;
        L2HopBridgerActionParams l2HopBridgerActionParams;
    }

    struct L2HopBridgerActionParams {
        address impl;
        address admin;
        address[] managers;
        uint256 maxDeadline;
        uint256 maxSlippage;
        uint256 maxBonderFeePct;
        uint256 destinationChainId;
        HopAmmParams[] hopAmmParams;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct HopAmmParams {
        address token;
        address amm;
    }

    constructor(address owner) BaseSmartVaultDeployer(owner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function deploy(Params memory params) external onlyOwner {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.manager, params.smartVaultParams);
        _setupSwapper(smartVault, params.manager, params.paraswapSwapperActionParams, ParaswapSwapper.call.selector);
        _setupL2HopBridger(smartVault, params.manager, params.l2HopBridgerActionParams);
        Deployer.transferPermissionManagerControl(params.manager, params.owners);
    }

    function _setupL2HopBridger(
        SmartVault smartVault,
        PermissionsManager manager,
        L2HopBridgerActionParams memory params
    ) internal {
        // Create and setup action
        L2HopBridger bridger = L2HopBridger(payable(params.impl));
        Deployer.setupBaseAction(bridger, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(bridger, manager, executors, bridger.call.selector);
        Deployer.setupRelayedAction(bridger, manager, params.admin, params.relayedActionParams);
        Deployer.setupTokenThresholdAction(bridger, manager, params.admin, params.tokenThresholdActionParams);

        // Set bridger max deadline
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setMaxDeadline.selector);
        bridger.setMaxDeadline(params.maxDeadline);
        manager.unauthorize(bridger, address(this), bridger.setMaxDeadline.selector);

        // Set bridger max slippage
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setMaxSlippage.selector);
        bridger.setMaxSlippage(params.maxSlippage);
        manager.unauthorize(bridger, address(this), bridger.setMaxSlippage.selector);

        // Set bridger max bonder fee pct
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setMaxBonderFeePct.selector);
        bridger.setMaxBonderFeePct(params.maxBonderFeePct);
        manager.unauthorize(bridger, address(this), bridger.setMaxBonderFeePct.selector);

        // Set bridger AMMs
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setTokenAmm.selector);
        for (uint256 i = 0; i < params.hopAmmParams.length; i = i.uncheckedAdd(1)) {
            HopAmmParams memory hopAmmParam = params.hopAmmParams[i];
            bridger.setTokenAmm(hopAmmParam.token, hopAmmParam.amm);
        }
        manager.unauthorize(bridger, address(this), bridger.setTokenAmm.selector);

        // Set bridger destination chain ID
        manager.authorize(bridger, Arrays.from(params.admin, address(this)), bridger.setDestinationChainId.selector);
        bridger.setDestinationChainId(params.destinationChainId);
        manager.unauthorize(bridger, address(this), bridger.setDestinationChainId.selector);

        // Authorize action to bridge and withdraw from Smart Vault
        bytes4[] memory whats = Arrays.from(smartVault.bridge.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(bridger), whats);
    }
}