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

import './actions/L2HopBridger.sol';
import './actions/L2HopSwapper.sol';
import './BaseSmartVaultDeployer.sol';

// solhint-disable avoid-low-level-calls

contract L2BridgingSmartVaultDeployer is BaseSmartVaultDeployer {
    using UncheckedMath for uint256;

    struct Params {
        IRegistry registry;
        Deployer.SmartVaultParams smartVaultParams;
        FunderActionParams funderActionParams;
        HolderActionParams holderActionParams;
        L2HopSwapperActionParams l2HopSwapperActionParams;
        L2HopBridgerActionParams l2HopBridgerActionParams;
    }

    struct L2HopSwapperActionParams {
        address impl;
        address admin;
        address[] managers;
        uint256 maxSlippage;
        HopAmmParams[] hopAmmParams;
    }

    struct L2HopBridgerActionParams {
        address impl;
        address admin;
        address[] managers;
        uint256 maxDeadline;
        uint256 maxSlippage;
        uint256 maxBonderFeePct;
        uint256[] allowedChainIds;
        HopAmmParams[] hopAmmParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct HopAmmParams {
        address token;
        address amm;
    }

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.smartVaultParams, false);
        _setupFunderAction(smartVault, params.funderActionParams);
        _setupHolderAction(smartVault, params.holderActionParams);
        _setupL2HopSwapperAction(smartVault, params.l2HopSwapperActionParams);
        _setupL2HopBridgerAction(smartVault, params.l2HopBridgerActionParams);
        Deployer.transferAdminPermissions(smartVault, params.smartVaultParams.admin);
    }

    function _setupL2HopSwapperAction(SmartVault smartVault, L2HopSwapperActionParams memory params) internal {
        // Create and setup action
        L2HopSwapper swapper = L2HopSwapper(params.impl);
        Deployer.setupBaseAction(swapper, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, new address[](0));
        Deployer.setupActionExecutors(swapper, executors, swapper.call.selector);

        // Set swapper max slippage
        swapper.authorize(params.admin, swapper.setMaxSlippage.selector);
        swapper.authorize(address(this), swapper.setMaxSlippage.selector);
        swapper.setMaxSlippage(params.maxSlippage);
        swapper.unauthorize(address(this), swapper.setMaxSlippage.selector);

        // Set swapper AMMs
        swapper.authorize(params.admin, swapper.setTokenAmm.selector);
        swapper.authorize(address(this), swapper.setTokenAmm.selector);
        for (uint256 i = 0; i < params.hopAmmParams.length; i = i.uncheckedAdd(1)) {
            HopAmmParams memory hopAmmParam = params.hopAmmParams[i];
            swapper.setTokenAmm(hopAmmParam.token, hopAmmParam.amm);
        }
        swapper.unauthorize(address(this), swapper.setTokenAmm.selector);

        // Transfer admin permissions to admin
        Deployer.transferAdminPermissions(swapper, params.admin);

        // Authorize action to swap from Smart Vault
        smartVault.authorize(address(swapper), smartVault.swap.selector);
    }

    function _setupL2HopBridgerAction(SmartVault smartVault, L2HopBridgerActionParams memory params) internal {
        // Create and setup action
        L2HopBridger bridger = L2HopBridger(payable(params.impl));
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

        // Set bridger max bonder fee pct
        bridger.authorize(params.admin, bridger.setMaxBonderFeePct.selector);
        bridger.authorize(address(this), bridger.setMaxBonderFeePct.selector);
        bridger.setMaxBonderFeePct(params.maxBonderFeePct);
        bridger.unauthorize(address(this), bridger.setMaxBonderFeePct.selector);

        // Set bridger AMMs
        bridger.authorize(params.admin, bridger.setTokenAmm.selector);
        bridger.authorize(address(this), bridger.setTokenAmm.selector);
        for (uint256 i = 0; i < params.hopAmmParams.length; i = i.uncheckedAdd(1)) {
            HopAmmParams memory hopAmmParam = params.hopAmmParams[i];
            bridger.setTokenAmm(hopAmmParam.token, hopAmmParam.amm);
        }
        bridger.unauthorize(address(this), bridger.setTokenAmm.selector);

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