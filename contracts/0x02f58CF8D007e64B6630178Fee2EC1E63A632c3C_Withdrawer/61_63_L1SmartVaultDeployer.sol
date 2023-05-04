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

import '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsManager.sol';

import './BaseSmartVaultDeployer.sol';
import './actions/swap/ParaswapSwapper.sol';
import './actions/withdraw/Withdrawer.sol';

// solhint-disable avoid-low-level-calls

contract L1SmartVaultDeployer is BaseSmartVaultDeployer {
    using PermissionsHelpers for PermissionsManager;

    struct Params {
        address[] owners;
        IRegistry registry;
        PermissionsManager manager;
        Deployer.SmartVaultParams smartVaultParams;
        SwapperActionParams paraswapSwapperActionParams;
        WithdrawerActionParams withdrawerActionParams;
    }

    struct WithdrawerActionParams {
        address impl;
        address admin;
        address[] managers;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.WithdrawalActionParams withdrawalActionParams;
        Deployer.TimeLockedActionParams timeLockedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    constructor(address owner) BaseSmartVaultDeployer(owner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function deploy(Params memory params) external onlyOwner {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.manager, params.smartVaultParams);
        _setupSwapper(smartVault, params.manager, params.paraswapSwapperActionParams, ParaswapSwapper.call.selector);
        _setupWithdrawer(smartVault, params.manager, params.withdrawerActionParams);
        Deployer.transferPermissionManagerControl(params.manager, params.owners);
    }

    function _setupWithdrawer(SmartVault smartVault, PermissionsManager manager, WithdrawerActionParams memory params)
        internal
    {
        // Create and setup action
        Withdrawer withdrawer = Withdrawer(params.impl);
        Deployer.setupBaseAction(withdrawer, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(withdrawer, manager, executors, withdrawer.call.selector);
        Deployer.setupRelayedAction(withdrawer, manager, params.admin, params.relayedActionParams);
        Deployer.setupTokenThresholdAction(withdrawer, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupWithdrawalAction(withdrawer, manager, params.admin, params.withdrawalActionParams);

        // Authorize action to withdraw from Smart Vault
        manager.authorize(smartVault, address(withdrawer), smartVault.withdraw.selector);
    }
}