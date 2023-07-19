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

import './actions/ERC20Claimer.sol';
import './actions/NativeClaimer.sol';
import './actions/SwapFeeSetter.sol';

// solhint-disable avoid-low-level-calls

contract SmartVaultDeployer {
    using UncheckedMath for uint256;

    struct Params {
        address mimic;
        IRegistry registry;
        ERC20ClaimerActionParams erc20ClaimerActionParams;
        NativeClaimerActionParams nativeClaimerActionParams;
        SwapFeeSetterActionParams swapFeeSetterActionParams;
        Deployer.SmartVaultParams smartVaultParams;
    }

    struct NativeClaimerActionParams {
        address impl;
        address admin;
        address[] managers;
        FeeClaimerParams feeClaimerParams;
    }

    struct ERC20ClaimerActionParams {
        address impl;
        address admin;
        address[] managers;
        address swapSigner;
        uint256 maxSlippage;
        address[] tokenSwapIgnores;
        FeeClaimerParams feeClaimerParams;
    }

    struct FeeClaimerParams {
        address feeClaimer;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct SwapFeeSetterActionParams {
        address impl;
        address admin;
        address[] managers;
        Deployer.SmartVaultFeeParams[] feeParams;
        Deployer.TimeLockedActionParams timeLockedActionParams;
    }

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.smartVaultParams, false);
        _setupERC20ClaimerAction(smartVault, params.erc20ClaimerActionParams, params.mimic);
        _setupNativeClaimerAction(smartVault, params.nativeClaimerActionParams, params.mimic);
        _setupSwapFeeSetterAction(smartVault, params.swapFeeSetterActionParams, params.mimic);
        Deployer.grantAdminPermissions(smartVault, params.mimic);
        Deployer.transferAdminPermissions(smartVault, params.smartVaultParams.admin);
    }

    function _setupSwapFeeSetterAction(SmartVault smartVault, SwapFeeSetterActionParams memory params, address mimic)
        internal
    {
        // Create and setup action
        SwapFeeSetter setter = SwapFeeSetter(params.impl);
        Deployer.setupBaseAction(setter, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, new address[](0));
        Deployer.setupActionExecutors(setter, executors, setter.call.selector);
        Deployer.setupTimeLockedAction(setter, params.admin, params.timeLockedActionParams);

        // Set fees, no need to authorize admin, fees can only be set once
        setter.authorize(address(this), setter.setFees.selector);
        setter.setFees(_castToFeeParams(params.feeParams));
        setter.unauthorize(address(this), setter.setFees.selector);
        Deployer.grantAdminPermissions(setter, mimic);
        Deployer.transferAdminPermissions(setter, params.admin);

        // Authorize action to withdraw and set swap fee
        smartVault.authorize(address(setter), smartVault.withdraw.selector);
        smartVault.authorize(address(setter), smartVault.setSwapFee.selector);
        smartVault.unauthorize(params.admin, smartVault.setSwapFee.selector);
    }

    function _setupNativeClaimerAction(SmartVault smartVault, NativeClaimerActionParams memory params, address mimic)
        internal
    {
        // Create and setup action
        NativeClaimer claimer = NativeClaimer(params.impl);
        Deployer.setupBaseAction(claimer, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(
            params.admin,
            params.managers,
            params.feeClaimerParams.relayedActionParams.relayers
        );
        Deployer.setupActionExecutors(claimer, executors, claimer.call.selector);
        Deployer.setupRelayedAction(claimer, params.admin, params.feeClaimerParams.relayedActionParams);
        _setupBaseClaimerAction(claimer, params.admin, params.feeClaimerParams);
        Deployer.grantAdminPermissions(claimer, mimic);
        Deployer.transferAdminPermissions(claimer, params.admin);

        // Authorize action to call and wrap
        smartVault.authorize(address(claimer), smartVault.call.selector);
        smartVault.authorize(address(claimer), smartVault.wrap.selector);
        smartVault.authorize(address(claimer), smartVault.withdraw.selector);
    }

    function _setupERC20ClaimerAction(SmartVault smartVault, ERC20ClaimerActionParams memory params, address mimic)
        internal
    {
        // Create and setup action
        ERC20Claimer claimer = ERC20Claimer(params.impl);
        Deployer.setupBaseAction(claimer, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(
            params.admin,
            params.managers,
            params.feeClaimerParams.relayedActionParams.relayers
        );
        Deployer.setupActionExecutors(claimer, executors, claimer.call.selector);
        Deployer.setupRelayedAction(claimer, params.admin, params.feeClaimerParams.relayedActionParams);
        _setupBaseClaimerAction(claimer, params.admin, params.feeClaimerParams);
        _setupSwapSignerAction(claimer, params.admin, params.swapSigner);
        _setupMaxSlippageAction(claimer, params.admin, params.maxSlippage);
        _setupTokenSwapIgnoresAction(claimer, params.admin, params.tokenSwapIgnores);
        Deployer.grantAdminPermissions(claimer, mimic);
        Deployer.transferAdminPermissions(claimer, params.admin);

        // Authorize action to call and swap
        smartVault.authorize(address(claimer), smartVault.call.selector);
        smartVault.authorize(address(claimer), smartVault.swap.selector);
        smartVault.authorize(address(claimer), smartVault.withdraw.selector);
    }

    function _setupBaseClaimerAction(BaseClaimer claimer, address admin, FeeClaimerParams memory params) internal {
        Deployer.setupTokenThresholdAction(claimer, admin, params.tokenThresholdActionParams);

        claimer.authorize(admin, claimer.setFeeClaimer.selector);
        claimer.authorize(address(this), claimer.setFeeClaimer.selector);
        claimer.setFeeClaimer(params.feeClaimer);
        claimer.unauthorize(address(this), claimer.setFeeClaimer.selector);
    }

    function _setupSwapSignerAction(ERC20Claimer claimer, address admin, address signer) internal {
        claimer.authorize(admin, claimer.setSwapSigner.selector);
        claimer.authorize(address(this), claimer.setSwapSigner.selector);
        claimer.setSwapSigner(signer);
        claimer.unauthorize(address(this), claimer.setSwapSigner.selector);
    }

    function _setupMaxSlippageAction(ERC20Claimer claimer, address admin, uint256 maxSlippage) internal {
        claimer.authorize(admin, claimer.setMaxSlippage.selector);
        claimer.authorize(address(this), claimer.setMaxSlippage.selector);
        claimer.setMaxSlippage(maxSlippage);
        claimer.unauthorize(address(this), claimer.setMaxSlippage.selector);
    }

    function _setupTokenSwapIgnoresAction(ERC20Claimer claimer, address admin, address[] memory ignores) internal {
        claimer.authorize(admin, claimer.setIgnoreTokenSwaps.selector);
        claimer.authorize(address(this), claimer.setIgnoreTokenSwaps.selector);
        claimer.setIgnoreTokenSwaps(ignores, _trues(ignores.length));
        claimer.unauthorize(address(this), claimer.setIgnoreTokenSwaps.selector);
    }

    function _castToFeeParams(Deployer.SmartVaultFeeParams[] memory params)
        internal
        pure
        returns (SwapFeeSetter.Fee[] memory result)
    {
        assembly {
            result := params
        }
    }

    function _trues(uint256 length) internal pure returns (bool[] memory arr) {
        arr = new bool[](length);
        for (uint256 i = 0; i < length; i = i.uncheckedAdd(1)) arr[i] = true;
    }
}