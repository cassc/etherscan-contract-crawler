//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract UniswapV3Twap {
	address private constant factoryV3Address = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
	IUniswapV3Factory public immutable factoryV3;
    
	constructor() {
		factoryV3 = IUniswapV3Factory(factoryV3Address);
    }

    function estimateAmountOut(address tokenIn, 
		address tokenOut,
        uint24 fee,		
		uint128 amountIn,
		uint32 secondsAgo
    ) external view returns (uint amountOut) {
        address pool = factoryV3.getPool(
            tokenIn,
            tokenOut,
            fee
        );
		
        require(pool != address(0), "pool doesn't exist");
		
		uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

        int24 tick = int24(tickCumulativesDelta / secondsAgo);
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % secondsAgo != 0)) {
            tick--;
        }

        amountOut = OracleLibrary.getQuoteAtTick(
            tick,
            amountIn,
            tokenIn,
            tokenOut
        );
    }
}