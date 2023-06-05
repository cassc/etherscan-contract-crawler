// SPDX-License-Identifier: MIT
// UniswapV2 dynamic price check for bonds @ https://bondswap.org

pragma solidity ^0.8.19;

import "./interfaces/IUniswap.sol";
import "./libs/UniswapHelpers.sol";

contract UniV2RewardCheck {
	address public immutable uniV2pair;

	constructor(address _uniV2pair) {
		uniV2pair = _uniV2pair;
	}

	function getRewardAmountForETH(address payoutToken, uint256 value) external view returns (uint256) {
		(uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(uniV2pair).getReserves();

		uint256 wmReserve;
		uint256 ethReserve;
		if (IUniswapV2Pair(uniV2pair).token0() == payoutToken) {
			wmReserve = reserve0;
			ethReserve = reserve1;
		} else {
			wmReserve = reserve1;
			ethReserve = reserve0;
		}

		uint256 reward = UniswapHelpers.getAmountOut(value, ethReserve, wmReserve);

		return reward;
	}
}