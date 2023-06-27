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
import '@mimic-fi/v2-swap-connector/contracts/ISwapConnector.sol';

import './BaseSwapper.sol';
import './interfaces/IOneInchV5Swapper.sol';

contract OneInchV5Swapper is IOnceInchV5Swapper, BaseSwapper {
    using FixedPoint for uint256;

    // Base gas amount charged to cover gas payment
    uint256 public constant override BASE_GAS = 30e3;

    /**
     * @dev Creates a 1inch v5 swapper action
     */
    constructor(SwapperConfig memory swapperConfig) BaseSwapper(swapperConfig) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Execution function
     */
    function call(address tokenIn, uint256 amountIn, uint256 slippage, bytes memory data)
        external
        actionCall(tokenIn, amountIn)
    {
        _validateSlippage(tokenIn, slippage);

        address tokenOut = _getApplicableTokenOut(tokenIn);
        uint256 price = _getPrice(tokenIn, tokenOut);
        uint256 minAmountOut = amountIn.mulUp(price).mulUp(FixedPoint.ONE - slippage);

        smartVault.swap(
            uint8(ISwapConnector.Source.OneInchV5),
            tokenIn,
            tokenOut,
            amountIn,
            ISmartVault.SwapLimit.MinAmountOut,
            minAmountOut,
            data
        );
    }
}