// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IUniswapV2Pair
{
	function token0() external view returns (address _token0);
	function token1() external view returns (address _token1);
	function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

	function mint(address _to) external returns (uint256 _liquidity);
	function burn(address _to) external returns (uint256 _amount0, uint256 _amount1);
	function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external;
}