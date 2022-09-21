// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '../UniV3likeQuoterCore.sol';
import './lib/TickBitmap.sol';

contract UniV3QuoterCore is UniV3likeQuoterCore {

    function getPoolGlobalState(
        address pool
    ) internal override view returns (GlobalState memory gs) {
        gs.fee = uint16(IUniswapV3Pool(pool).fee());
        (gs.startPrice, gs.startTick,,,,,) = IUniswapV3Pool(pool).slot0();
    }
    
    function getTickSpacing(
        address pool
    ) internal override view returns (int24) {
        return IUniswapV3Pool(pool).tickSpacing();
    }
    
    function getLiquidity(address pool) internal override view returns (uint128) {
        return IUniswapV3Pool(pool).liquidity();
    }
    
    function nextInitializedTickWithinOneWord(
        address poolAddress,
        int24 tick,
        int24 tickSpacing,
        bool zeroForOne
    ) internal override view returns (int24 next, bool initialized) {
        return TickBitmap.nextInitializedTickWithinOneWord(
            poolAddress,
            tick,
            tickSpacing,
            zeroForOne
        );
    }
    
    function getTicks(address pool, int24 tick) internal override view returns (
        uint128 liquidityTotal,
        int128 liquidityDelta,
        uint256 outerFeeGrowth0Token,
        uint256 outerFeeGrowth1Token,
        int56 outerTickCumulative,
        uint160 outerSecondsPerLiquidity,
        uint32 outerSecondsSpent,
        bool initialized
    ) {
        return IUniswapV3Pool(pool).ticks(tick);
    }

}