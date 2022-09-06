pragma solidity ^0.8.0;

import "../lib/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

interface IUniswapV2SlidingOracle {
    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    function factory() external returns (address);

    function windowSize() external returns (uint256);

    function granularity() external returns (uint8);

    function periodSize() external returns (uint256);

    function observationIndexOf(uint256 timestamp) external view returns (uint8 index);

    function update(address tokenA, address tokenB) external;

    function consult(address tokenIn, uint256 amountIn, address tokenOut) external view returns (uint256 amountOut);
}