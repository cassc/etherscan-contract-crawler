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

import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TimeLockedAction.sol';

contract SwapFeeSetter is BaseAction, TimeLockedAction {
    struct Fee {
        uint256 pct;
        uint256 cap;
        address token;
        uint256 period;
    }

    Fee[] public fees;
    uint256 public nextFeeIndex;

    event FeesSet(Fee[] fees);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function canExecute() external view returns (bool) {
        return fees.length > 0 && nextFeeIndex < fees.length && _passesTimeLock();
    }

    function setFees(Fee[] memory _fees) external auth {
        require(fees.length == 0, 'FEES_ALREADY_SET');
        for (uint256 i = 0; i < _fees.length; i++) fees.push(_fees[i]);
        emit FeesSet(_fees);
    }

    function call() external auth nonReentrant {
        require(fees.length > 0, 'FEES_NOT_SET');
        require(nextFeeIndex < fees.length, 'FEE_CONFIGS_ALREADY_EXECUTED');
        _validateTimeLock();

        Fee memory fee = fees[nextFeeIndex++];
        smartVault.setSwapFee(fee.pct, fee.cap, fee.token, fee.period);
        emit Executed();
    }
}