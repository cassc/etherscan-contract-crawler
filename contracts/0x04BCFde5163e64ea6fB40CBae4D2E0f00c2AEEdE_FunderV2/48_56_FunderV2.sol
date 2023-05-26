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

contract FunderV2 is BaseAction, WithdrawalAction {
    using FixedPoint for uint256;

    address public tokenIn;
    uint256 public minBalance;
    uint256 public maxBalance;
    uint256 public maxSlippage;

    event TokenInSet(address indexed tokenIn);
    event MaxSlippageSet(uint256 maxSlippage);
    event BalanceLimitsSet(uint256 min, uint256 max);

    constructor(
        address _smartVault,
        address _tokenIn,
        uint256 _minBalance,
        uint256 _maxBalance,
        uint256 _maxSlippage,
        address _recipient,
        address _admin,
        address _owner,
        address _registry
    ) BaseAction(_owner, _registry) {
        require(address(_smartVault) != address(0), 'SMART_VAULT_ZERO');
        smartVault = ISmartVault(_smartVault);
        emit SmartVaultSet(_smartVault);

        _setTokenIn(_tokenIn);
        _setBalanceLimits(_minBalance, _maxBalance);
        _setMaxSlippage(_maxSlippage);

        require(_recipient != address(0), 'RECIPIENT_ZERO');
        recipient = _recipient;
        emit RecipientSet(_recipient);

        _authorize(_admin, BaseAction.setSmartVault.selector);
        _authorize(_admin, FunderV2.setTokenIn.selector);
        _authorize(_admin, FunderV2.setBalanceLimits.selector);
        _authorize(_admin, FunderV2.setMaxSlippage.selector);
        _authorize(_admin, WithdrawalAction.setRecipient.selector);
    }

    function fundeableAmount() public view returns (uint256) {
        if (recipient.balance >= minBalance) return 0;

        uint256 diff = maxBalance - recipient.balance;
        if (_isWrappedOrNativeToken(tokenIn)) return diff;

        uint256 price = smartVault.getPrice(smartVault.wrappedNativeToken(), tokenIn);
        return diff.mulUp(price);
    }

    function canExecute(uint256 amountIn, uint256 slippage) external view returns (bool) {
        return
            recipient != address(0) &&
            tokenIn != address(0) &&
            minBalance > 0 &&
            maxBalance > 0 &&
            amountIn <= fundeableAmount() &&
            slippage <= maxSlippage;
    }

    function setTokenIn(address token) external auth {
        _setTokenIn(token);
    }

    function setBalanceLimits(uint256 min, uint256 max) external auth {
        _setBalanceLimits(min, max);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        _setMaxSlippage(newMaxSlippage);
    }

    function call(uint8 source, uint256 amountIn, uint256 slippage, bytes memory data) external auth nonReentrant {
        require(recipient != address(0), 'FUNDER_RECIPIENT_NOT_SET');
        require(minBalance > 0, 'FUNDER_BALANCE_LIMIT_NOT_SET');
        require(tokenIn != address(0), 'FUNDER_TOKEN_IN_NOT_SET');
        require(amountIn > 0, 'FUNDER_AMOUNT_IN_ZERO');
        require(amountIn <= fundeableAmount(), 'FUNDER_AMOUNT_IN_ABOVE_MAX');
        require(slippage <= maxSlippage, 'FUNDER_SLIPPAGE_ABOVE_MAX');

        uint256 toWithdraw = Denominations.isNativeToken(tokenIn) ? amountIn : _swap(source, amountIn, slippage, data);
        _withdraw(Denominations.NATIVE_TOKEN, toWithdraw);
        emit Executed();
    }

    function _swap(uint8 source, uint256 amountIn, uint256 slippage, bytes memory data) private returns (uint256) {
        address wrappedNativeToken = smartVault.wrappedNativeToken();
        uint256 toUnwrap = tokenIn == wrappedNativeToken
            ? amountIn
            : smartVault.swap(
                source,
                tokenIn,
                wrappedNativeToken,
                amountIn,
                ISmartVault.SwapLimit.Slippage,
                slippage,
                data
            );
        return smartVault.unwrap(toUnwrap, new bytes(0));
    }

    function _setTokenIn(address token) private {
        require(token != address(0), 'FUNDER_TOKEN_IN_ZERO');
        tokenIn = token;
        emit TokenInSet(token);
    }

    function _setBalanceLimits(uint256 min, uint256 max) private {
        require(min <= max, 'FUNDER_MIN_GT_MAX');
        minBalance = min;
        maxBalance = max;
        emit BalanceLimitsSet(min, max);
    }

    function _setMaxSlippage(uint256 newMaxSlippage) private {
        require(newMaxSlippage <= FixedPoint.ONE, 'SWAPPER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }
}