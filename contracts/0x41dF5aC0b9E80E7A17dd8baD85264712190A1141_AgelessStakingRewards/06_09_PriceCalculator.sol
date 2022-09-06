// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './Utilities.sol';

abstract contract PriceCalculator is Utilities {
	function _getTokenPrice(
		IUniswapV2Router02 router,
		address[] memory tokenToStable
	) internal view virtual returns (uint256) {
		//special case where token is stable
		if (tokenToStable.length == 1) {
			return 1e18;
		}

		uint256[] memory amounts = router.getAmountsOut(1e18, tokenToStable);
		// stable token decimal is currently 6 so change to 18 decimals
		return amounts[amounts.length - 1] * 1e12;
	}

	function getTokenPriceInEthPair(
		IUniswapV2Router02 router,
		address token
	) public view virtual returns (uint256) {
		address WETH = router.WETH();
		address[] memory pair = new address[](2);
		pair[0] = token;
		pair[1] = WETH;
		uint256[] memory amounts = router.getAmountsOut(1e18, pair);
		uint256 amountInETH = amounts[amounts.length - 1];
		uint256 chainId = _getChainID();
		return amountInETH * _getETHPrice(router, usdc[chainId]) / 1e18;
	}

	function _getETHPrice(
		IUniswapV2Router02 router,
		address stableToken
	) internal view virtual returns (uint256) {
		address WETH = router.WETH();
		address[] memory tokenToStable = new address[](2);
		tokenToStable[0] = WETH;
		tokenToStable[1] = stableToken;
		return _getTokenPrice(router, tokenToStable);
	}

	function _getLPTokenPrice(
		IUniswapV2Router02 router,
		address[] memory token0ToStable,
		address[] memory token1ToStable,
		IERC20 lpToken
	) internal view virtual returns (uint256) {
		uint256 token0InPool = IERC20(token0ToStable[0]).balanceOf(
			address(lpToken)
		);
		uint256 token1InPool = IERC20(token1ToStable[0]).balanceOf(
			address(lpToken)
		);

		uint256 totalPriceOfPool = token0InPool *
			(_getTokenPrice(router, token0ToStable)) +
			token1InPool *
			(_getTokenPrice(router, token1ToStable));

		return totalPriceOfPool / (lpToken.totalSupply());
	}
}