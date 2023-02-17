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

import './BaseClaimer.sol';

contract NativeClaimer is BaseClaimer {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 65e3;

    constructor(address admin, address registry) BaseClaimer(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function canExecute(address token) external view override returns (bool) {
        return
            _isWrappedOrNativeToken(token) &&
            _passesThreshold(smartVault.wrappedNativeToken(), _thresholdBalance(token));
    }

    function call(address token) external auth nonReentrant redeemGas(_wrappedIfNative(token)) {
        require(_isWrappedOrNativeToken(token), 'NATIVE_CLAIMER_INVALID_TOKEN');
        _validateThreshold(smartVault.wrappedNativeToken(), _thresholdBalance(token));

        _claim(token);
        if (Denominations.isNativeToken(token)) smartVault.wrap(address(smartVault).balance, new bytes(0));
        emit Executed();
    }

    function _thresholdBalance(address token) internal view returns (uint256) {
        uint256 amountToClaim = claimableBalance(token);
        uint256 wrappableBalance = Denominations.isNativeToken(token) ? address(smartVault).balance : 0;
        return amountToClaim + wrappableBalance;
    }
}