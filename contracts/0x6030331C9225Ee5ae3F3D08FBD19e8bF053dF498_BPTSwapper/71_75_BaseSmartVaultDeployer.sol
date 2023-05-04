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

import '@openzeppelin/contracts/access/Ownable.sol';

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/BaseDeployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/deploy/Deployer.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/Arrays.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/permissions/PermissionsHelpers.sol';

import './actions/claim/Claimer.sol';
import './actions/swap/BPTSwapper.sol';
import './actions/swap/BaseSwapper.sol';

// solhint-disable avoid-low-level-calls

contract BaseSmartVaultDeployer is BaseDeployer {
    using UncheckedMath for uint256;
    using PermissionsHelpers for PermissionsManager;

    struct ClaimerActionParams {
        address impl;
        address admin;
        address[] managers;
        address oracleSigner;
        address payingGasToken;
        address protocolFeeWithdrawer;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct BptSwapperActionParams {
        address impl;
        address admin;
        address[] managers;
        address oracleSigner;
        address payingGasToken;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct SwapperActionParams {
        address impl;
        address admin;
        address[] managers;
        address tokenOut;
        address swapSigner;
        address[] deniedTokens;
        uint256 defaultMaxSlippage;
        address[] customSlippageTokens;
        uint256[] customSlippageValues;
        Deployer.RelayedActionParams relayedActionParams;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    constructor(address owner) BaseDeployer(owner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function _setupClaimer(SmartVault smartVault, PermissionsManager manager, ClaimerActionParams memory params)
        internal
    {
        // Create and setup action
        Claimer claimer = Claimer(params.impl);
        Deployer.setupBaseAction(claimer, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(claimer, manager, executors, claimer.call.selector);
        Deployer.setupTokenThresholdAction(claimer, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupRelayedAction(claimer, manager, params.admin, params.relayedActionParams);

        // Set oracle signers
        manager.authorize(claimer, Arrays.from(params.admin, address(this)), claimer.setOracleSigner.selector);
        claimer.setOracleSigner(params.oracleSigner, true);
        manager.unauthorize(claimer, address(this), claimer.setOracleSigner.selector);

        // Set paying gas token
        manager.authorize(claimer, Arrays.from(params.admin, address(this)), claimer.setPayingGasToken.selector);
        claimer.setPayingGasToken(params.payingGasToken);
        manager.unauthorize(claimer, address(this), claimer.setPayingGasToken.selector);

        // Set protocol fee withdrawer
        manager.authorize(claimer, Arrays.from(params.admin, address(this)), claimer.setProtocolFeeWithdrawer.selector);
        claimer.setProtocolFeeWithdrawer(params.protocolFeeWithdrawer);
        manager.unauthorize(claimer, address(this), claimer.setProtocolFeeWithdrawer.selector);

        // Authorize action to call and withdraw
        bytes4[] memory whats = Arrays.from(smartVault.call.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(claimer), whats);
    }

    function _setupBptSwapper(SmartVault smartVault, PermissionsManager manager, BptSwapperActionParams memory params)
        internal
    {
        // Create and setup action
        BPTSwapper swapper = BPTSwapper(params.impl);
        Deployer.setupBaseAction(swapper, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(swapper, manager, executors, swapper.call.selector);
        Deployer.setupTokenThresholdAction(swapper, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupRelayedAction(swapper, manager, params.admin, params.relayedActionParams);

        // Set oracle signers
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setOracleSigner.selector);
        swapper.setOracleSigner(params.oracleSigner, true);
        manager.unauthorize(swapper, address(this), swapper.setOracleSigner.selector);

        // Set paying gas token
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setPayingGasToken.selector);
        swapper.setPayingGasToken(params.payingGasToken);
        manager.unauthorize(swapper, address(this), swapper.setPayingGasToken.selector);

        // Authorize action to call and withdraw
        bytes4[] memory whats = Arrays.from(smartVault.call.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(swapper), whats);
    }

    function _setupSwapper(
        SmartVault smartVault,
        PermissionsManager manager,
        SwapperActionParams memory params,
        bytes4 selector
    ) internal {
        // Create and setup action
        BaseSwapper swapper = BaseSwapper(params.impl);
        Deployer.setupBaseAction(swapper, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.managers, params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(swapper, manager, executors, selector);
        Deployer.setupTokenThresholdAction(swapper, manager, params.admin, params.tokenThresholdActionParams);
        Deployer.setupRelayedAction(swapper, manager, params.admin, params.relayedActionParams);

        // Set token out
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setTokenOut.selector);
        swapper.setTokenOut(params.tokenOut);
        manager.unauthorize(swapper, address(this), swapper.setTokenOut.selector);

        // Set swap signer
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setSwapSigner.selector);
        swapper.setSwapSigner(params.swapSigner);
        manager.unauthorize(swapper, address(this), swapper.setSwapSigner.selector);

        // Set default max slippage
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setDefaultMaxSlippage.selector);
        swapper.setDefaultMaxSlippage(params.defaultMaxSlippage);
        manager.unauthorize(swapper, address(this), swapper.setDefaultMaxSlippage.selector);

        // Set custom token max slippages
        bool isCustomSlippageLengthValid = params.customSlippageTokens.length == params.customSlippageValues.length;
        require(isCustomSlippageLengthValid, 'DEPLOYER_SLIPPAGES_INVALID_LEN');
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setTokenMaxSlippage.selector);
        for (uint256 i = 0; i < params.customSlippageTokens.length; i++) {
            swapper.setTokenMaxSlippage(params.customSlippageTokens[i], params.customSlippageValues[i]);
        }
        manager.unauthorize(swapper, address(this), swapper.setTokenMaxSlippage.selector);

        // Deny requested tokens
        manager.authorize(swapper, Arrays.from(params.admin, address(this)), swapper.setDeniedTokens.selector);
        swapper.setDeniedTokens(params.deniedTokens, _trues(params.deniedTokens.length));
        manager.unauthorize(swapper, address(this), swapper.setDeniedTokens.selector);

        // Authorize action to swap and withdraw
        bytes4[] memory whats = Arrays.from(smartVault.swap.selector, smartVault.withdraw.selector);
        manager.authorize(smartVault, address(swapper), whats);
    }

    function _trues(uint256 length) internal pure returns (bool[] memory arr) {
        arr = new bool[](length);
        for (uint256 i = 0; i < length; i = i.uncheckedAdd(1)) arr[i] = true;
    }
}