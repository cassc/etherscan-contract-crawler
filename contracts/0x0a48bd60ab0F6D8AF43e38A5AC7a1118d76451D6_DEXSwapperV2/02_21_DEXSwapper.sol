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

import './BaseSwapper.sol';

contract DEXSwapper is BaseSwapper {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 35e3;

    constructor(address admin, address registry) BaseAction(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function canExecute(uint256 amountIn, uint256 slippage) public view virtual returns (bool) {
        return
            tokenIn != address(0) &&
            tokenOut != address(0) &&
            slippage <= maxSlippage &&
            _passesThreshold(tokenIn, amountIn);
    }

    function call(uint8 source, uint256 amountIn, uint256 slippage, bytes memory data) external auth {
        (isRelayer[msg.sender] ? _relayedCall : _call)(source, amountIn, slippage, data);
    }

    function _relayedCall(uint8 source, uint256 amountIn, uint256 slippage, bytes memory data) internal redeemGas {
        _call(source, amountIn, slippage, data);
    }

    function _call(uint8 source, uint256 amountIn, uint256 slippage, bytes memory data) internal {
        _validateSwap(amountIn, slippage);
        smartVault.swap(source, tokenIn, tokenOut, amountIn, ISmartVault.SwapLimit.Slippage, slippage, data);
        emit Executed();
    }

    function _validateSwap(uint256 amountIn, uint256 slippage) internal virtual {
        require(tokenIn != address(0), 'SWAPPER_TOKEN_IN_NOT_SET');
        require(tokenOut != address(0), 'SWAPPER_TOKEN_OUT_NOT_SET');
        require(slippage <= maxSlippage, 'SWAPPER_SLIPPAGE_ABOVE_MAX');
        _validateThreshold(tokenIn, amountIn);
    }
}