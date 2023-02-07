// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "../interfaces/uniswap/IUniswapV2Factory.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniUtils {
	using SafeERC20 for IERC20;

	function _getPairTokens(IUniswapV2Pair pair) internal view returns (address, address) {
		return (pair.token0(), pair.token1());
	}

	function _getPairReserves(
		IUniswapV2Pair pair,
		address tokenA,
		address tokenB
	) internal view returns (uint256 reserveA, uint256 reserveB) {
		(address token0, ) = _sortTokens(tokenA, tokenB);
		(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
		(reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// given some amount of an asset and lp reserves, returns an equivalent amount of the other asset
	function _quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) internal pure returns (uint256 amountB) {
		require(amountA > 0, "UniUtils: INSUFFICIENT_AMOUNT");
		require(reserveA > 0 && reserveB > 0, "UniUtils: INSUFFICIENT_LIQUIDITY");
		amountB = (amountA * reserveB) / reserveA;
	}

	function _sortTokens(address tokenA, address tokenB)
		internal
		pure
		returns (address token0, address token1)
	{
		require(tokenA != tokenB, "UniUtils: IDENTICAL_ADDRESSES");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "UniUtils: ZERO_ADDRESS");
	}

	function _getAmountOut(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal view returns (uint256 amountOut) {
		require(amountIn > 0, "UniUtils: INSUFFICIENT_INPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function _getAmountIn(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal view returns (uint256 amountIn) {
		require(amountOut > 0, "UniUtils: INSUFFICIENT_OUTPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}

	function _swapExactTokensForTokens(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountOut = _getAmountOut(pair, amountIn, inToken, outToken);
		if (amountOut == 0) return 0;
		_swap(pair, amountIn, amountOut, inToken, outToken);
		return amountOut;
	}

	function _swapTokensForExactTokens(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountIn = _getAmountIn(pair, amountOut, inToken, outToken);
		_swap(pair, amountIn, amountOut, inToken, outToken);
		return amountIn;
	}

	function _swap(
		IUniswapV2Pair pair,
		uint256 amountIn,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal {
		(address token0, ) = _sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));
		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
	}
}