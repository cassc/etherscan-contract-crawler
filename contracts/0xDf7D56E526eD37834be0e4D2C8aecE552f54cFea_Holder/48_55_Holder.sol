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

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/BaseAction.sol';
import '@mimic-fi/v2-smart-vaults-base/contracts/actions/TokenThresholdAction.sol';

contract Holder is BaseAction, TokenThresholdAction {
    address public tokenOut;
    uint256 public maxSlippage;

    event TokenOutSet(address indexed tokenOut);
    event MaxSlippageSet(uint256 maxSlippage);

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function canExecute(address tokenIn, uint256 amountIn, uint256 slippage) external view returns (bool) {
        if (tokenOut == address(0) || slippage > maxSlippage) return false;
        return _passesThreshold(tokenIn, amountIn);
    }

    function setTokenOut(address token) external auth {
        require(token != address(0), 'HOLDER_TOKEN_OUT_ZERO');
        require(!Denominations.isNativeToken(token), 'HOLDER_NATIVE_TOKEN_OUT');
        tokenOut = token;
        emit TokenOutSet(token);
    }

    function setMaxSlippage(uint256 newMaxSlippage) external auth {
        require(newMaxSlippage <= FixedPoint.ONE, 'HOLDER_SLIPPAGE_ABOVE_ONE');
        maxSlippage = newMaxSlippage;
        emit MaxSlippageSet(newMaxSlippage);
    }

    function call(uint8 source, address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data)
        external
        auth
        nonReentrant
    {
        require(tokenOut != address(0), 'HOLDER_TOKEN_OUT_NOT_SET');
        require(tokenIn != address(0), 'HOLDER_TOKEN_IN_ZERO');
        require(tokenIn != tokenOut, 'HOLDER_TOKEN_IN_EQ_OUT');
        require(slippage <= maxSlippage, 'HOLDER_SLIPPAGE_ABOVE_MAX');
        _validateThreshold(tokenIn, amountIn);

        if (Denominations.isNativeToken(tokenIn)) amountIn = smartVault.wrap(amountIn, new bytes(0));
        tokenIn = _wrappedIfNative(tokenIn);

        if (tokenIn != tokenOut) {
            // token in might haven been updated to be the wrapped native token
            smartVault.swap(source, tokenIn, tokenOut, amountIn, ISmartVault.SwapLimit.Slippage, slippage, data);
        }

        emit Executed();
    }
}