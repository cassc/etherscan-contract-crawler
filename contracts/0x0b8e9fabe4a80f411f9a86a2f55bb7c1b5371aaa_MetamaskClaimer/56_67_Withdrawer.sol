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

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TimeLockedAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/WithdrawalAction.sol';

contract Withdrawer is BaseAction, RelayedAction, TimeLockedAction, TokenThresholdAction, WithdrawalAction {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 100e3;

    constructor(
        address _smartVault,
        address _recipient,
        uint256 _timeLock,
        address _thresholdToken,
        uint256 _thresholdAmount,
        address _relayer,
        uint256 _gasPriceLimit,
        uint256 _txCostLimit,
        address _admin,
        address _registry
    ) BaseAction(_admin, _registry) {
        require(_smartVault != address(0), 'WITHDRAWER_SMART_VAULT_ZERO');
        smartVault = ISmartVault(_smartVault);
        emit SmartVaultSet(_smartVault);

        require(_recipient != address(0), 'WITHDRAWER_RECIPIENT_ZERO');
        recipient = _recipient;
        emit RecipientSet(_recipient);

        if (_timeLock > 0) {
            period = _timeLock;
            emit TimeLockSet(_timeLock);
        }

        if (_thresholdToken != address(0) && _thresholdAmount > 0) {
            thresholdToken = _thresholdToken;
            thresholdAmount = _thresholdAmount;
            emit ThresholdSet(_thresholdToken, _thresholdAmount);
        }

        if (_relayer != address(0)) {
            isRelayer[_relayer] = true;
            emit RelayerSet(_relayer, true);
        }

        if (_gasPriceLimit > 0 || _txCostLimit > 0) {
            gasPriceLimit = _gasPriceLimit;
            txCostLimit = _txCostLimit;
            emit LimitsSet(_gasPriceLimit, _txCostLimit);
        }
    }

    function call(address token) external auth nonReentrant {
        _initRelayedTx();
        _validateTimeLock();

        uint256 amount = _balanceOf(token);
        _validateThreshold(token, amount);
        emit Executed();

        _payRelayedTx(token);
        _withdraw(token);
    }
}