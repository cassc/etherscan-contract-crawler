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

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

import { UncheckedMath } from '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import { IRegistry } from '@mimic-fi/v2-registry/contracts/registry/IRegistry.sol';
import { SmartVault } from '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import { Deployer } from '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import { Arrays } from '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import { PermissionsHelpers } from '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';
import { PermissionsManager } from '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsManager.sol';

import { Swapper } from './Swapper.sol';

contract SmartVaultDeployer is Ownable {
    using PermissionsHelpers for PermissionsManager;

    struct Params {
        address[] owners;
        IRegistry registry;
        PermissionsManager manager;
        SwapperActionParams swapperActionParams;
        Deployer.SmartVaultParams smartVaultParams;
    }

    struct SwapperActionParams {
        address impl;
        address admin;
        uint8[] sources;
    }

    constructor(address owner) {
        _transferOwnership(owner);
    }

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.manager, params.smartVaultParams);
        _setupSwapperAction(smartVault, params.manager, params.swapperActionParams);
        Deployer.transferPermissionManagerControl(params.manager, params.owners);
    }

    function _setupSwapperAction(SmartVault smartVault, PermissionsManager manager, SwapperActionParams memory params)
        internal
    {
        // Create and setup action
        Swapper swapper = Swapper(params.impl);
        Deployer.setupBaseAction(swapper, manager, params.admin, address(smartVault));

        // Set up allowed sources
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setSource.selector);
        for (uint256 i = 0; i < params.sources.length; i++) swapper.setSource(params.sources[i], true);
        manager.unauthorize(swapper, address(this), swapper.setSource.selector);

        // Set up pause permissions
        manager.authorize(swapper, params.admin, Arrays.from(swapper.pause.selector, swapper.unpause.selector));

        // Authorize action to collect, swap, wrap, unwrap, and withdraw
        manager.authorize(
            smartVault,
            address(swapper),
            Arrays.from(
                smartVault.collect.selector,
                smartVault.swap.selector,
                smartVault.wrap.selector,
                smartVault.unwrap.selector,
                smartVault.withdraw.selector
            )
        );
    }
}