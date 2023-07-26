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
import '@mimic-fi/v2-smart-vault/contracts/SmartVault.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';

import './actions/Funder.sol';
import './actions/Holder.sol';

// solhint-disable avoid-low-level-calls

contract BaseSmartVaultDeployer {
    struct FunderActionParams {
        address impl;
        address admin;
        address[] managers;
        address tokenIn;
        uint256 minBalance;
        uint256 maxBalance;
        uint256 maxSlippage;
        Deployer.WithdrawalActionParams withdrawalActionParams;
    }

    struct HolderActionParams {
        address impl;
        address admin;
        address[] managers;
        address tokenOut;
        uint256 maxSlippage;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    function _setupFunderAction(SmartVault smartVault, FunderActionParams memory params) internal {
        // Create and setup action
        Funder funder = Funder(params.impl);
        Deployer.setupBaseAction(funder, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, new address[](0));
        Deployer.setupActionExecutors(funder, executors, funder.call.selector);
        Deployer.setupWithdrawalAction(funder, params.admin, params.withdrawalActionParams);

        // Set funder token in
        funder.authorize(params.admin, funder.setTokenIn.selector);
        funder.authorize(address(this), funder.setTokenIn.selector);
        funder.setTokenIn(params.tokenIn);
        funder.unauthorize(address(this), funder.setTokenIn.selector);

        // Set funder balance limits
        funder.authorize(params.admin, funder.setBalanceLimits.selector);
        funder.authorize(address(this), funder.setBalanceLimits.selector);
        funder.setBalanceLimits(params.minBalance, params.maxBalance);
        funder.unauthorize(address(this), funder.setBalanceLimits.selector);

        // Set funder max slippage
        funder.authorize(params.admin, funder.setMaxSlippage.selector);
        funder.authorize(address(this), funder.setMaxSlippage.selector);
        funder.setMaxSlippage(params.maxSlippage);
        funder.unauthorize(address(this), funder.setMaxSlippage.selector);

        // Transfer admin permissions to admin
        Deployer.transferAdminPermissions(funder, params.admin);

        // Authorize action to swap, unwrap, and withdraw from Smart Vault
        smartVault.authorize(address(funder), smartVault.swap.selector);
        smartVault.authorize(address(funder), smartVault.unwrap.selector);
        smartVault.authorize(address(funder), smartVault.withdraw.selector);
    }

    function _setupHolderAction(SmartVault smartVault, HolderActionParams memory params) internal {
        // Create and setup action
        Holder holder = Holder(params.impl);
        Deployer.setupBaseAction(holder, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, new address[](0));
        Deployer.setupActionExecutors(holder, executors, holder.call.selector);
        Deployer.setupTokenThresholdAction(holder, params.admin, params.tokenThresholdActionParams);

        // Set holder token out
        holder.authorize(params.admin, holder.setTokenOut.selector);
        holder.authorize(address(this), holder.setTokenOut.selector);
        holder.setTokenOut(params.tokenOut);
        holder.unauthorize(address(this), holder.setTokenOut.selector);

        // Set holder max slippage
        holder.authorize(params.admin, holder.setMaxSlippage.selector);
        holder.authorize(address(this), holder.setMaxSlippage.selector);
        holder.setMaxSlippage(params.maxSlippage);
        holder.unauthorize(address(this), holder.setMaxSlippage.selector);

        // Transfer admin permissions to admin
        Deployer.transferAdminPermissions(holder, params.admin);

        // Authorize action to wrap and swap from Smart Vault
        smartVault.authorize(address(holder), smartVault.wrap.selector);
        smartVault.authorize(address(holder), smartVault.swap.selector);
    }
}