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

import './BaseSmartVaultDeployer.sol';

contract L2NoBridgingSmartVaultDeployer is BaseSmartVaultDeployer {
    struct Params {
        IRegistry registry;
        Deployer.SmartVaultParams smartVaultParams;
        FunderActionParams funderActionParams;
        HolderActionParams holderActionParams;
    }

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.smartVaultParams, false);
        _setupFunderAction(smartVault, params.funderActionParams);
        _setupHolderAction(smartVault, params.holderActionParams);
        Deployer.transferAdminPermissions(smartVault, params.smartVaultParams.admin);
    }
}