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

import '../../deploy/Deployer.sol';
import '../actions/ReceiverActionMock.sol';
import '../actions/RelayedActionMock.sol';
import '../actions/TokenThresholdActionMock.sol';
import '../actions/TimeLockedActionMock.sol';
import '../actions/WithdrawalActionMock.sol';

// solhint-disable avoid-low-level-calls

contract DeployerMock {
    struct Params {
        IRegistry registry;
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
        SmartVault smartVault = Deployer.createSmartVault(params.registry, params.smartVaultParams, false);
        _setupReceiverAction(smartVault, params.receiverActionParams);
        _setupRelayedAction(smartVault, params.relayedActionParams);
        _setupTokenThresholdAction(smartVault, params.tokenThresholdActionParams);
        _setupTimeLockedAction(smartVault, params.timeLockedActionParams);
        _setupWithdrawalAction(smartVault, params.withdrawalActionParams);
        Deployer.transferAdminPermissions(smartVault, params.smartVaultParams.admin);
    }

    function _setupReceiverAction(SmartVault smartVault, ReceiverActionParams memory params) internal {
        ReceiverActionMock action = ReceiverActionMock(payable(params.impl));
        Deployer.setupBaseAction(action, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, _arr(params.admin), action.withdraw.selector);
        Deployer.setupReceiverAction(action, params.admin);
        Deployer.transferAdminPermissions(action, params.admin);
    }

    function _setupRelayedAction(SmartVault smartVault, RelayedActionParams memory params) internal {
        RelayedActionMock action = RelayedActionMock(params.impl);
        Deployer.setupBaseAction(action, params.admin, address(smartVault));
        address[] memory executors = Arrays.from(params.admin, params.relayedActionParams.relayers, new address[](0));
        Deployer.setupActionExecutors(action, executors, action.call.selector);
        Deployer.setupRelayedAction(action, params.admin, params.relayedActionParams);
        Deployer.transferAdminPermissions(action, params.admin);
    }

    function _setupTokenThresholdAction(SmartVault smartVault, TokenThresholdActionParams memory params) internal {
        TokenThresholdActionMock action = TokenThresholdActionMock(params.impl);
        Deployer.setupBaseAction(action, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, _arr(params.admin), action.call.selector);
        Deployer.setupTokenThresholdAction(action, params.admin, params.tokenThresholdActionParams);
        Deployer.transferAdminPermissions(action, params.admin);
    }

    function _setupTimeLockedAction(SmartVault smartVault, TimeLockedActionParams memory params) internal {
        TimeLockedActionMock action = TimeLockedActionMock(params.impl);
        Deployer.setupBaseAction(action, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, _arr(params.admin), action.call.selector);
        Deployer.setupTimeLockedAction(action, params.admin, params.timeLockedActionParams);
        Deployer.transferAdminPermissions(action, params.admin);
    }

    function _setupWithdrawalAction(SmartVault smartVault, WithdrawalActionParams memory params) internal {
        WithdrawalActionMock action = WithdrawalActionMock(params.impl);
        Deployer.setupBaseAction(action, params.admin, address(smartVault));
        Deployer.setupActionExecutors(action, _arr(params.admin), action.call.selector);
        Deployer.setupWithdrawalAction(action, params.admin, params.withdrawalActionParams);
        Deployer.transferAdminPermissions(action, params.admin);
    }

    function _arr(address a) internal pure returns (address[] memory r) {
        r = new address[](1);
        r[0] = a;
    }
}