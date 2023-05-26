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

import './DEXSwapper.sol';

contract DEXSwapperV2 is DEXSwapper {
    using FixedPoint for uint256;

    struct SwapLimit {
        address token;
        uint256 amount;
        uint256 accrued;
        uint256 period;
        uint256 nextResetTime;
    }

    SwapLimit public swapLimit;

    event SwapLimitSet(address indexed token, uint256 amount, uint256 period);

    struct DEXSwapperV2Params {
        address smartVault;
        address tokenIn;
        address tokenOut;
        uint256 maxSlippage;
        address swapLimitToken;
        uint256 swapLimitAmount;
        uint256 swapLimitPeriod;
        address thresholdToken;
        uint256 thresholdAmount;
        address relayer;
        uint256 gasPriceLimit;
        uint256 totalCostLimit;
        address payingGasToken;
        address admin;
        address registry;
    }

    constructor(DEXSwapperV2Params memory params) DEXSwapper(params.admin, params.registry) {
        require(params.smartVault != address(0), 'SWAPPER_SMART_VAULT_ZERO');
        smartVault = ISmartVault(params.smartVault);
        emit SmartVaultSet(params.smartVault);

        require(params.tokenIn != address(0), 'SWAPPER_TOKEN_IN_ZERO');
        tokenIn = params.tokenIn;
        emit TokenInSet(params.tokenIn);

        require(params.tokenOut != address(0), 'SWAPPER_TOKEN_OUT_ZERO');
        require(params.tokenIn != params.tokenOut, 'SWAPPER_TOKEN_OUT_EQ_IN');
        tokenOut = params.tokenOut;
        emit TokenOutSet(params.tokenOut);

        _setSwapLimit(params.swapLimitToken, params.swapLimitAmount, params.swapLimitPeriod);

        if (params.maxSlippage > 0) {
            require(params.maxSlippage <= FixedPoint.ONE, 'SWAPPER_SLIPPAGE_ABOVE_ONE');
            maxSlippage = params.maxSlippage;
            emit MaxSlippageSet(params.maxSlippage);
        }

        if (params.thresholdToken != address(0) && params.thresholdAmount > 0) {
            thresholdToken = params.thresholdToken;
            thresholdAmount = params.thresholdAmount;
            emit ThresholdSet(params.thresholdToken, params.thresholdAmount);
        }

        if (params.relayer != address(0)) {
            isRelayer[params.relayer] = true;
            _authorize(params.relayer, DEXSwapper.call.selector);
            emit RelayerSet(params.relayer, true);
        }

        if (params.payingGasToken != address(0) && (params.gasPriceLimit > 0 || params.totalCostLimit > 0)) {
            gasPriceLimit = params.gasPriceLimit;
            totalCostLimit = params.totalCostLimit;
            payingGasToken = params.payingGasToken;
            emit LimitsSet(params.gasPriceLimit, params.totalCostLimit, params.payingGasToken);
        }
    }

    function setSwapLimit(address token, uint256 amount, uint256 period) external auth {
        _setSwapLimit(token, amount, period);
    }

    function canExecute(uint256 amountIn, uint256 slippage) public view override returns (bool) {
        if (!super.canExecute(amountIn, slippage)) return false;
        (bool exceedsLimit, ) = _computeSwappedAmount(amountIn);
        return !exceedsLimit;
    }

    function _computeSwappedAmount(uint256 amountIn) internal view returns (bool exceedsLimit, uint256 swappedAmount) {
        if (swapLimit.amount == 0 || swapLimit.token == address(0)) return (false, 0);

        if (tokenIn == swapLimit.token) {
            swappedAmount = amountIn;
        } else {
            uint256 price = smartVault.getPrice(tokenIn, swapLimit.token);
            swappedAmount = amountIn.mulDown(price);
        }

        uint256 totalSwapped = swappedAmount + (block.timestamp < swapLimit.nextResetTime ? swapLimit.accrued : 0);
        exceedsLimit = totalSwapped > swapLimit.amount;
    }

    function _validateSwap(uint256 amountIn, uint256 slippage) internal override {
        super._validateSwap(amountIn, slippage);

        (bool exceedsLimit, uint256 swappedAmount) = _computeSwappedAmount(amountIn);
        require(!exceedsLimit, 'SWAPPER_SWAP_LIMIT_EXCEEDED');

        if (block.timestamp >= swapLimit.nextResetTime) {
            swapLimit.accrued = 0;
            swapLimit.nextResetTime = block.timestamp + swapLimit.period;
        }

        swapLimit.accrued += swappedAmount;
    }

    function _setSwapLimit(address token, uint256 amount, uint256 period) internal {
        // If there is no limit, all values must be zero
        bool isZeroLimit = token == address(0) && amount == 0 && period == 0;
        bool isNonZeroLimit = token != address(0) && amount > 0 && period > 0;
        require(isZeroLimit || isNonZeroLimit, 'SWAPPER_INVALID_SWAP_LIMIT_INPUT');

        // Changing the period only affects the end time of the next period, but not the end date of the current one
        swapLimit.period = period;

        // Changing the amount does not affect the totalizator, it only applies when changing the accrued amount.
        // Note that it can happen that the new amount is lower than the accrued amount if the amount is lowered.
        // However, there shouldn't be any accounting issues with that.
        swapLimit.amount = amount;

        // Therefore, only clean the totalizators if the limit is being removed
        if (isZeroLimit) {
            swapLimit.accrued = 0;
            swapLimit.nextResetTime = 0;
        } else {
            // If limit is not zero, set the next reset time if it wasn't set already
            // Otherwise, if the token is being changed the accrued amount must be updated accordingly
            if (swapLimit.nextResetTime == 0) {
                swapLimit.accrued = 0;
                swapLimit.nextResetTime = block.timestamp + period;
            } else if (swapLimit.token != token) {
                uint256 price = smartVault.getPrice(swapLimit.token, token);
                swapLimit.accrued = swapLimit.accrued.mulDown(price);
            }
        }

        // Finally simply set the new requested token
        swapLimit.token = token;
        emit SwapLimitSet(token, amount, period);
    }
}