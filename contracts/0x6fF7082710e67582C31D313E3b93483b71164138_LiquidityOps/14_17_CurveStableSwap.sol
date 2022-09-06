pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (liquidity-pools/CurveStableSwap.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/external/curve/ICurveStableSwap.sol";

import "../common/CommonEventsAndErrors.sol";

/// @notice A wrapper around Curve v1 stable swap
library CurveStableSwap {
    using SafeERC20 for IERC20;

    struct Data {
        ICurveStableSwap pool;
        IERC20 token0;
        IERC20 token1;
    }

    event CoinExchanged(address coinSent, uint256 amountSent, uint256 amountReceived);
    event RemovedLiquidityImbalance(uint256 receivedAmount0, uint256 receivedAmount1, uint256 burnAmount);
    event LiquidityAdded(uint256 sentAmount0, uint256 sentAmount1, uint256 curveTokenAmount);
    event LiquidityRemoved(uint256 receivedAmount0, uint256 receivedAmount1, uint256 curveTokenAmount);

    error InvalidSlippage(uint256 slippage);

    uint256 internal constant CURVE_FEE_DENOMINATOR = 1e10;

    function exchangeQuote(
        Data storage self,
        address _coinIn,
        uint256 _fromAmount
    ) internal view returns (uint256) {
        (, int128 inIndex, int128 outIndex) = _getExchangeInfo(self, _coinIn);
        return self.pool.get_dy(inIndex, outIndex, _fromAmount);
    }

    function exchange(
        Data storage self,
        address _coinIn,
        uint256 _amount,
        uint256 _minAmountOut,
        address _receiver
    ) internal returns (uint256 amountOut) {
        (IERC20 tokenIn, int128 inIndex, int128 outIndex) = _getExchangeInfo(self, _coinIn);

        uint256 balance = tokenIn.balanceOf(address(this));
        if (balance < _amount) revert CommonEventsAndErrors.InsufficientBalance(address(tokenIn), _amount, balance);
        tokenIn.safeIncreaseAllowance(address(self.pool), _amount);

        amountOut = self.pool.exchange(inIndex, outIndex, _amount, _minAmountOut, _receiver);
        emit CoinExchanged(_coinIn, _amount, amountOut);
    }

    function _getExchangeInfo(
        Data storage self,
        address _coinIn
    ) private view returns (IERC20 tokenIn, int128 inIndex, int128 outIndex) {
        if (_coinIn == address(self.token0)) {
            (tokenIn, inIndex, outIndex) = (self.token0, 0, 1);
        } else if (_coinIn == address(self.token1)) {
            (tokenIn, inIndex, outIndex) = (self.token1, 1, 0);
        } else {
            revert CommonEventsAndErrors.InvalidToken(_coinIn);
        }
    }

    function removeLiquidityImbalance(
        Data storage self,
        uint256[2] memory _amounts,
        uint256 _maxBurnAmount
    ) internal returns (uint256 burnAmount) {
        uint256 balance = self.pool.balanceOf(address(this));
        if (balance <= 0) revert CommonEventsAndErrors.InsufficientBalance(address(self.pool), 1, balance);
        burnAmount = self.pool.remove_liquidity_imbalance(_amounts, _maxBurnAmount, address(this));

        emit RemovedLiquidityImbalance(_amounts[0], _amounts[1], burnAmount);
    }

    /** 
      * @notice Add LP/xLP 1:1 into the curve pool
      * @dev Add same amounts of lp and xlp tokens such that the price remains about the same
             - don't apply any peg fixing here. xLP tokens are minted 1:1
      * @param _amount The amount of LP and xLP to add into the pool.
      * @param _minAmountOut The minimum amount of curve liquidity tokens we expect in return.
      */
    function addLiquidity(
        Data storage self,
        uint256 _amount,
        uint256 _minAmountOut
    ) internal returns (uint256 liquidity) {
        uint256[2] memory amounts = [_amount, _amount];
        
        self.token0.safeIncreaseAllowance(address(self.pool), _amount);
        self.token1.safeIncreaseAllowance(address(self.pool), _amount);

        liquidity = self.pool.add_liquidity(amounts, _minAmountOut, address(this));
        emit LiquidityAdded(_amount, _amount, liquidity);
    }

    function removeLiquidity(
        Data storage self,
        uint256 _liquidity,
        uint256 _minAmount0,
        uint256 _minAmount1
    ) internal returns (uint256[2] memory balancesOut) {
        uint256 balance = self.pool.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientBalance(address(self.pool), _liquidity, balance);
        balancesOut = self.pool.remove_liquidity(_liquidity, [_minAmount0, _minAmount1]);
        emit LiquidityRemoved(balancesOut[0], balancesOut[1], _liquidity);
    }

    /** 
      * @notice Calculates the min expected amount of curve liquidity token to receive when depositing the 
      *         current eligible amount to into the curve LP:xLP liquidity pool
      * @dev Takes into account pool liquidity slippage and fees.
      * @param _liquidity The amount of LP to apply
      * @param _modelSlippage Any extra slippage to account for, given curveStableSwap.calc_token_amount() 
               is an approximation. 1e10 precision, so 1% = 1e8.
      * @return minCurveTokenAmount Expected amount of LP tokens received 
      */ 
    function minAmountOut(
        Data storage self,
        uint256 _liquidity,
        uint256 _modelSlippage
    ) internal view returns (uint256 minCurveTokenAmount) {
        uint256 feeAndSlippage = _modelSlippage + self.pool.fee();        if (feeAndSlippage > CURVE_FEE_DENOMINATOR) revert InvalidSlippage(feeAndSlippage);
        
        minCurveTokenAmount = 0;
        if (_liquidity > 0) {
            uint256[2] memory amounts = [_liquidity, _liquidity];
            minCurveTokenAmount = self.pool.calc_token_amount(amounts, true);
            unchecked {
                minCurveTokenAmount -= minCurveTokenAmount * feeAndSlippage / CURVE_FEE_DENOMINATOR;
            }
        }
    }

}