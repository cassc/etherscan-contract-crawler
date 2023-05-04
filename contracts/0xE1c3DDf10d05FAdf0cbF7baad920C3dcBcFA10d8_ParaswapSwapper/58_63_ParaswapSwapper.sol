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

import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseSwapper.sol';

contract ParaswapSwapper is BaseSwapper {
    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 46e3;

    constructor(address admin, address registry) BaseSwapper(admin, registry) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function call(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 expectedAmountOut,
        uint256 deadline,
        bytes memory data,
        bytes memory sig
    ) external auth nonReentrant redeemGas(tokenOut) {
        _validateToken(tokenIn);
        _validateThreshold(tokenOut, minAmountOut);
        _validateSlippage(tokenIn, minAmountOut, expectedAmountOut);
        _validateSig(tokenIn, amountIn, minAmountOut, expectedAmountOut, deadline, data, sig);

        smartVault.swap(
            uint8(ISwapConnector.Source.ParaswapV5),
            tokenIn,
            tokenOut,
            amountIn,
            ISmartVault.SwapLimit.MinAmountOut,
            minAmountOut,
            data
        );

        emit Executed();
    }
}