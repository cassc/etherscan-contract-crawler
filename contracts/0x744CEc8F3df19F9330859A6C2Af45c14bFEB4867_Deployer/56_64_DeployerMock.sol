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

import '../../deploy/Deployer.sol';
import '../../permissions/Arrays.sol';
import '../actions/ReceiverActionMock.sol';
import '../actions/RelayedActionMock.sol';
import '../actions/TokenThresholdActionMock.sol';
import '../actions/TimeLockedActionMock.sol';
import '../actions/WithdrawalActionMock.sol';

// solhint-disable avoid-low-level-calls

contract DeployerMock {
    struct Params {
        address owner;
        IRegistry registry;
        PermissionsManager manager;
        Deployer.SmartVaultParams smartVaultParams;
        ReceiverActionParams receiverActionParams;
        RelayedActionParams relayedActionParams;
        TokenThresholdActionParams tokenThresholdActionParams;
        TimeLockedActionParams timeLockedActionParams;
        WithdrawalActionParams withdrawalActionParams;
    }

    struct ReceiverActionParams {
        address impl;
        address admin;
    }

    struct RelayedActionParams {
        address impl;
        address admin;
        Deployer.RelayedActionParams relayedActionParams;
    }

    struct TokenThresholdActionParams {
        address impl;
        address admin;
        Deployer.TokenThresholdActionParams tokenThresholdActionParams;
    }

    struct TimeLockedActionParams {
        address impl;
        address admin;
        Deployer.TimeLockedActionParams timeLockedActionParams;
    }

    struct WithdrawalActionParams {
        address impl;
        address admin;
        Deployer.WithdrawalActionParams withdrawalActionParams;
    }

    function deploy(Params memory params) external {
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.manager, params.smartVaultParams);
        _setupReceiverAction(smartVault, params.manager, params.receiverActionParams);
        _setupRelayedAction(smartVault, params.manager, params.relayedActionParams);
        _setupTokenThresholdAction(smartVault, params.manager, params.tokenThresholdActionParams);
        _setupTimeLockedAction(smartVault, params.manager, params.timeLockedActionParams);
        _setupWithdrawalAction(smartVault, params.manager, params.withdrawalActionParams);
        Deployer.transferPermissionManagerControl(params.manager, Arrays.from(params.owner));
    }

    function _setupReceiverAction(SmartVault smartVault, PermissionsManager manager, ReceiverActionParams memory params)
        internal
    {
        ReceiverActionMock action = ReceiverActionMock(payable(params.impl));
        Deployer.setupBaseAction(action, manager, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, manager, Arrays.from(params.admin), action.transferToSmartVault.selector);
        Deployer.setupReceiverAction(action, manager, params.admin);
    }

    function _setupRelayedAction(SmartVault smartVault, PermissionsManager manager, RelayedActionParams memory params)
        internal
    {
        RelayedActionMock action = RelayedActionMock(params.impl);
        Deployer.setupBaseAction(action, manager, params.admin, address(smartVault));
        address[] memory executors = Arrays.concat(Arrays.from(params.admin), params.relayedActionParams.relayers);
        Deployer.setupActionExecutors(action, manager, executors, action.call.selector);
        Deployer.setupRelayedAction(action, manager, params.admin, params.relayedActionParams);
    }

    function _setupTokenThresholdAction(
        SmartVault smartVault,
        PermissionsManager manager,
        TokenThresholdActionParams memory params
    ) internal {
        TokenThresholdActionMock action = TokenThresholdActionMock(params.impl);
        Deployer.setupBaseAction(action, manager, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, manager, Arrays.from(params.admin), action.call.selector);
        Deployer.setupTokenThresholdAction(action, manager, params.admin, params.tokenThresholdActionParams);
    }

    function _setupTimeLockedAction(
        SmartVault smartVault,
        PermissionsManager manager,
        TimeLockedActionParams memory params
    ) internal {
        TimeLockedActionMock action = TimeLockedActionMock(params.impl);
        Deployer.setupBaseAction(action, manager, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, manager, Arrays.from(params.admin), action.call.selector);
        Deployer.setupTimeLockedAction(action, manager, params.admin, params.timeLockedActionParams);
    }

    function _setupWithdrawalAction(
        SmartVault smartVault,
        PermissionsManager manager,
        WithdrawalActionParams memory params
    ) internal {
        WithdrawalActionMock action = WithdrawalActionMock(params.impl);
        Deployer.setupBaseAction(action, manager, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, manager, Arrays.from(params.admin), action.call.selector);
        Deployer.setupWithdrawalAction(action, manager, params.admin, params.withdrawalActionParams);
    }
}