// "SPDX-License-Identifier: MIT"

pragma solidity ^0.8.3;

interface Uniswap {
  function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external returns (uint256[] memory amounts);
  function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external payable returns (uint256[] memory amounts);
  function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline)
    external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
  function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline)
    external returns (uint amountA, uint amountB);
  function getPair(address tokenA, address tokenB)
    external view returns (address pair);
  function WETH() external pure returns (address);
  function getAmountsOut(uint amountIn, address[] memory path)
    external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] memory path)
    external view returns (uint[] memory amounts);
  function getReserves() 
    external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function factory() external view returns (address);
}