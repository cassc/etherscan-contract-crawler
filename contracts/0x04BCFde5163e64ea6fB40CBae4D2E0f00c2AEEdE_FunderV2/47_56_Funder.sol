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
import '@mimic-fi/v2-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/WithdrawalAction.sol';

contract Funder is BaseAction, WithdrawalAction {
    using FixedPoint for uint256;

    address public tokenIn;
    uint256 public minBalance;
    uint256 public maxBalance;
    uint256 public maxSlippage;

    event TokenInSet(address indexed tokenIn);
    event MaxSlippageSet(uint256 maxSlippage);
    event BalanceLimitsSet(uint256 min, uint256 max);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function fundeableAmount() external view returns (uint256) {
        if (recipient.balance >= minBalance) return 0;

        uint256 diff = maxBalance - recipient.balance;
        if (_isWrappedOrNativeToken(tokenIn)) return diff;

        uint256 price = smartVault.getPrice(smartVault.wrappedNativeToken(), tokenIn);
        return diff.mulUp(price);
    }

    function canExecute(uint256 slippage) external view returns (bool) {
        return
            recipient != address(0) &&
            minBalance > 0 &&
            maxBalance > 0 &&
            recipient.balance < minBalance &&
            tokenIn != address(0) &&
            slippage <= maxSlippage;
    }

    function setTokenIn(address token) external auth {
        require(token != address(0), 'FUNDER_TOKEN_IN_ZERO');
        tokenIn = token;
        emit TokenInSet(token);
    }

    function setBalanceLimits(uint256 min, uint256 max) external auth {
        require(min <= max, 'FUNDER_MIN_GT_MAX');
        minBalance = min;
        maxBalance = max;
        emit BalanceLimitsSet(min, max);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        require(newMaxSlippage <= FixedPoint.ONE, 'SWAPPER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }

    function call(uint8 source, uint256 slippage, bytes memory data) external auth nonReentrant {
        require(recipient != address(0), 'FUNDER_RECIPIENT_NOT_SET');
        require(minBalance > 0, 'FUNDER_BALANCE_LIMIT_NOT_SET');
        require(recipient.balance < minBalance, 'FUNDER_BALANCE_ABOVE_MIN');
        require(tokenIn != address(0), 'FUNDER_TOKEN_IN_NOT_SET');
        require(slippage <= maxSlippage, 'FUNDER_SLIPPAGE_ABOVE_MAX');

        uint256 toWithdraw = 0;
        uint256 diff = maxBalance - recipient.balance;
        if (Denominations.isNativeToken(tokenIn)) toWithdraw = diff;
        else {
            uint256 toUnwrap = 0;
            address wrappedNativeToken = smartVault.wrappedNativeToken();
            if (tokenIn == wrappedNativeToken) toUnwrap = diff;
            else {
                uint256 price = smartVault.getPrice(wrappedNativeToken, tokenIn);
                uint256 amountIn = diff.mulUp(price);
                toUnwrap = smartVault.swap(
                    source,
                    tokenIn,
                    wrappedNativeToken,
                    amountIn,
                    ISmartVault.SwapLimit.Slippage,
                    slippage,
                    data
                );
            }
            toWithdraw = smartVault.unwrap(toUnwrap, new bytes(0));
        }

        _withdraw(Denominations.NATIVE_TOKEN, toWithdraw);
        emit Executed();
    }
}