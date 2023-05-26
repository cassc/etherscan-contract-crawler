// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracleFactory {
    function create(address token0, address token1) external;
    function update(address token0, address token1) external;
    function consult(address tokenIn, uint256 amountIn, address tokenOut) external view returns (uint256 amountOut);
    function getOracle(address token0, address token1) external view returns (address oracle);
}