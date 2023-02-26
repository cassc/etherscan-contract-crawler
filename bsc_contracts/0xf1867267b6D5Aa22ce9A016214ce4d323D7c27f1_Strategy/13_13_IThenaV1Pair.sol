// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IV1Pair {
	function totalSupply() external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function decimals() external view returns (uint8);

	function symbol() external view returns (string memory);

	function balanceOf(address) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function isStable() external view returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 amount
	) external returns (bool);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function mint(address to) external returns (uint256 liquidity);

	function getReserves()
		external
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast
		);

	function getAmountOut(uint256, address) external view returns (uint256);

	function current(address tokenIn, uint256 amountIn)
		external
		view
		returns (uint256 amountOut);

	function quote(
		address tokenIn,
		uint256 amountIn,
		uint256 granularity
	) external view returns (uint256 amountOut);
}