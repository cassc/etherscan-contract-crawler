// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

// Uniswap V3 simulation query
struct TickNextWithWordQuery{
    address pool;
    int24 tick;
    int24 tickSpacing;
    bool lte;
}
	
struct UniV3SortPoolQuery{
    address _pool;
    address _token0;
    address _token1;
    uint24 _fee;
    uint256 amountIn;
    bool zeroForOne;
}

interface IUniswapV3Simulator {
    function simulateUniV3Swap(address _pool, address _token0, address _token1, bool _zeroForOne, uint24 _fee, uint256 _amountIn) external view returns (uint256);
    function checkInRangeLiquidity(UniV3SortPoolQuery memory _sortQuery) external view returns (bool, uint256);
}