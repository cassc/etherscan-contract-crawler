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

import '@mimic-fi/v2-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/RelayedAction.sol';

import '../interfaces/IFeeClaimer.sol';

// solhint-disable avoid-low-level-calls

abstract contract BaseClaimer is BaseAction, TokenThresholdAction, RelayedAction {
    address public feeClaimer;

    event FeeClaimerSet(address indexed feeClaimer);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function setFeeClaimer(address newFeeClaimer) external auth {
        feeClaimer = newFeeClaimer;
        emit FeeClaimerSet(newFeeClaimer);
    }

    function canExecute(address token) external view virtual returns (bool);

    function claimableBalance(address token) public view returns (uint256) {
        return IFeeClaimer(feeClaimer).getBalance(token, address(smartVault));
    }

    function totalBalance(address token) public view returns (uint256) {
        return claimableBalance(token) + _balanceOf(token);
    }

    function _claim(address token) internal {
        if (claimableBalance(token) == 0) return;
        bytes memory data = abi.encodeWithSelector(IFeeClaimer.withdrawAllERC20.selector, token, smartVault);
        bytes memory response = smartVault.call(feeClaimer, data, 0, new bytes(0));
        require(abi.decode(response, (bool)), 'FEE_CLAIMER_WITHDRAW_FAILED');
    }
}