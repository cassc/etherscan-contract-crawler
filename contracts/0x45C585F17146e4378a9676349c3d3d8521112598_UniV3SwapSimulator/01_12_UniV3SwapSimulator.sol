// SPDX-License-Identifier: MIT
pragma solidity 0.7.6; // some underlying uniswap library require version <0.8.0  
pragma abicoder v2;

import "SwapMath.sol";
import "TickBitmap.sol";
import "TickMath.sol";
import "FullMath.sol";
import "LiquidityMath.sol";
import "SqrtPriceMath.sol";
	
struct UniV3SortPoolQuery{
    address _pool;
    address _token0;
    address _token1;
    uint24 _fee;
    uint256 amountIn;
    bool zeroForOne;
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);
}

interface IUniswapV3PoolSwapTick {
    function slot0() external view returns (uint160 sqrtPriceX96, int24, uint16, uint16, uint16, uint8, bool);
    function liquidity() external view returns (uint128);
    function tickSpacing() external view returns (int24);
    function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, int56 tickCumulativeOutside, uint160 secondsPerLiquidityOutsideX128, uint32 secondsOutside, bool initialized);
}

// simplified version of https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L561
struct SwapStatus{
    int256 _amountSpecifiedRemaining;
    uint160 _sqrtPriceX96;
    int24 _tick;
    uint128 _liquidity;
    int256 _amountCalculated;
}

/// @dev Swap Simulator for Uniswap V3
contract UniV3SwapSimulator {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    
    /// @dev View function which aims to simplify Uniswap V3 swap logic (no oracle/fee update, etc) to 
    /// @dev estimate the expected output for given swap parameters and slippage
    /// @dev simplified version of https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Pool.sol#L596
    /// @return simulated output token amount using Uniswap V3 tick-based math
    function simulateUniV3Swap(address _pool, address _token0, address _token1, bool _zeroForOne, uint24 _fee, uint256 _amountIn) external view returns (uint256){        
        // Get current state of the pool
        int24 _tickSpacing = IUniswapV3PoolSwapTick(_pool).tickSpacing();
        // lower limit if zeroForOne in terms of slippage, or upper limit for the other direction
        uint160 _sqrtPriceLimitX96;
        // Temporary state holding key data across swap steps
        SwapStatus memory state;
		
        {
           (uint160 _currentPX96, int24 _currentTick,,,,,) = IUniswapV3PoolSwapTick(_pool).slot0();
           _sqrtPriceLimitX96 = _getLimitPrice(_zeroForOne);
           state = SwapStatus(_amountIn.toInt256(), _currentPX96, _currentTick, IUniswapV3PoolSwapTick(_pool).liquidity(), 0);
        }
		
        // Loop over ticks until we exhaust all _amountIn or hit the slippage-allowed price limit
        while (state._amountSpecifiedRemaining != 0 && state._sqrtPriceX96 != _sqrtPriceLimitX96) {
           {
               _stepInTick(state, TickNextWithWordQuery(_pool, state._tick, _tickSpacing, _zeroForOne), _fee, _zeroForOne, _sqrtPriceLimitX96);	
           }			
        }
		
        return uint256(state._amountCalculated);
    }	
	
    /// @dev allow caller to check if given amountIn would be satisfied with in-range liquidity
    /// @return true if in-range liquidity is good for the quote otherwise false which means a full cross-ticks simulation required
    function checkInRangeLiquidity(UniV3SortPoolQuery memory _sortQuery) public view returns (bool, uint256) {	
        uint128 _liq = IUniswapV3PoolSwapTick(_sortQuery._pool).liquidity();
		
        // are we swapping in a liquid-enough pool?
        if (_liq <= 0) {
           return (false, 0);
        }		
			 
        {
           (uint160 _swapAfterPrice, uint160 _tickNextPrice, uint160 _currentPriceX96) = _findSwapPriceExactIn(_sortQuery, _liq);           
           bool _crossTick = _sortQuery.zeroForOne? (_swapAfterPrice <= _tickNextPrice) : (_swapAfterPrice >= _tickNextPrice);
           if (_crossTick){
               return (true, 0);
           } else{            
               return (false, _getAmountOutputDelta(_swapAfterPrice, _currentPriceX96, _liq, _sortQuery.zeroForOne));
           }
        }             
	}
	
    /// @dev retrieve next initialized tick for given Uniswap V3 pool
    function _getNextInitializedTick(TickNextWithWordQuery memory _nextTickQuery) internal view returns (int24, bool, uint160) {	
        (int24 tickNext, bool initialized) = TickBitmap.nextInitializedTickWithinOneWord(_nextTickQuery);
        if (tickNext < TickMath.MIN_TICK) {
           tickNext = TickMath.MIN_TICK;
        } else if (tickNext > TickMath.MAX_TICK) {
           tickNext = TickMath.MAX_TICK;
        }
        uint160 sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(tickNext);
        return (tickNext, initialized, sqrtPriceNextX96);
    }
	
    /// @dev return calculated output amount in the Uniswap V3 pool for given price pair 
    /// @dev works for any swap that does not push the calculated next price past the price of the next initialized tick
    /// @dev check SwapMath for details
    function _getAmountOutputDelta(uint160 _nextPrice, uint160 _currentPrice, uint128 _liquidity, bool _zeroForOne) internal pure returns (uint256) {
        return _zeroForOne? SqrtPriceMath.getAmount1Delta(_nextPrice, _currentPrice, _liquidity, false) : SqrtPriceMath.getAmount0Delta(_currentPrice, _nextPrice, _liquidity, false);
    }
	
    /// @dev swap step in the tick
    function _stepInTick(SwapStatus memory state, TickNextWithWordQuery memory _nextTickQuery, uint24 _fee, bool _zeroForOne, uint160 _sqrtPriceLimitX96) view internal{
		
        /// Fetch NEXT-STEP tick to prepare for crossing
        (int24 tickNext, bool initialized, uint160 sqrtPriceNextX96) = _getNextInitializedTick(_nextTickQuery);
        uint160 sqrtPriceStartX96 = state._sqrtPriceX96;
        uint160 _targetPX96 = _getTargetPriceForSwapStep(_zeroForOne, sqrtPriceNextX96, _sqrtPriceLimitX96);
		
        /// Trying to perform in-tick swap
        {		    
           _swapCalculation(state, _targetPX96, _fee);
        }
						
        /// Check if we have to cross ticks for NEXT-STEP
        if (state._sqrtPriceX96 == sqrtPriceNextX96) {
           // if the tick is initialized, run the tick transition
           if (initialized) {
               (,int128 liquidityNet,,,,,,) = IUniswapV3PoolSwapTick(_nextTickQuery.pool).ticks(tickNext);
               // if we're moving leftward, we interpret liquidityNet as the opposite sign safe because liquidityNet cannot be type(int128).min
               if (_zeroForOne) liquidityNet = -liquidityNet;
               state._liquidity = LiquidityMath.addDelta(state._liquidity, liquidityNet);
           }
           state._tick = _zeroForOne ? tickNext - 1 : tickNext;				
        } else if (state._sqrtPriceX96 != sqrtPriceStartX96) {
           // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
           state._tick = TickMath.getTickAtSqrtRatio(state._sqrtPriceX96);
        }
    } 
	
    function _findSwapPriceExactIn(UniV3SortPoolQuery memory _sortQuery, uint128 _liq) internal view returns (uint160, uint160, uint160) {
        uint160 _tickNextPrice;
        uint160 _swapAfterPrice;
        (uint160 _currentPriceX96, int24 _tick,,,,,) = IUniswapV3PoolSwapTick(_sortQuery._pool).slot0();
		
        {
           TickNextWithWordQuery memory _nextTickQ = TickNextWithWordQuery(_sortQuery._pool, _tick, IUniswapV3PoolSwapTick(_sortQuery._pool).tickSpacing(), _sortQuery.zeroForOne);
           (,,uint160 _nxtTkP) = _getNextInitializedTick(_nextTickQ);
           _tickNextPrice = _nxtTkP;
        }
		
        {		
           uint160 _targetPX96 = _getTargetPriceForSwapStep(_sortQuery.zeroForOne, _tickNextPrice, _getLimitPrice(_sortQuery.zeroForOne));
           SwapExactInParam memory _exactInParams = SwapExactInParam(_sortQuery.amountIn, _sortQuery._fee, _currentPriceX96, _targetPX96, _liq, _sortQuery.zeroForOne);
           (uint256 _amtIn, uint160 _newPrice) = SwapMath._getExactInNextPrice(_exactInParams);
           _swapAfterPrice = _newPrice;
        }
        
        return (_swapAfterPrice, _tickNextPrice, _currentPriceX96);
    }
	
    /// @dev https://etherscan.io/address/0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6#code#F1#L95
    function _getLimitPrice(bool _zeroForOne) internal pure returns (uint160) {
        return _zeroForOne? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1;
    }
	
    function _getTargetPriceForSwapStep(bool _zeroForOne, uint160 sqrtPriceNextX96, uint160 _sqrtPriceLimitX96) internal pure returns (uint160) {
        return (_zeroForOne ? sqrtPriceNextX96 < _sqrtPriceLimitX96 : sqrtPriceNextX96 > _sqrtPriceLimitX96)? _sqrtPriceLimitX96 : sqrtPriceNextX96;
    }
	
    function _swapCalculation(SwapStatus memory state, uint160 _targetPX96, uint24 _fee) internal view {
        (uint160 sqrtPriceX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = SwapMath.computeSwapStep(state._sqrtPriceX96, _targetPX96, state._liquidity, state._amountSpecifiedRemaining, _fee);
			
        /// Update amounts for swap pair tokens
        state._sqrtPriceX96 = sqrtPriceX96; 
        state._amountSpecifiedRemaining -= (amountIn + feeAmount).toInt256();
        state._amountCalculated = state._amountCalculated.add(amountOut.toInt256());
    }

}