// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUniswapV2Router01 } from "../../interfaces/uniswap/IUniswapV2Router01.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { HarvestSwapParams, IBase } from "./IBase.sol";

abstract contract IFarmable is IBase {
	using SafeERC20 for IERC20;

	event HarvestedToken(address indexed token, uint256 amount);

	function _swap(
		IUniswapV2Router01 router,
		HarvestSwapParams calldata swapParams,
		address from,
		uint256 amount
	) internal returns (uint256[] memory) {
		address out = swapParams.path[swapParams.path.length - 1];
		// ensure malicious harvester is not trading with wrong tokens
		// TODO should we add more validation to prevent malicious path?
		require(
			((swapParams.path[0] == address(from) && (out == address(short()))) ||
				out == address(underlying())),
			"IFarmable: WRONG_PATH"
		);
		return
			router.swapExactTokensForTokens(
				amount,
				swapParams.min,
				swapParams.path, // optimal route determined externally
				address(this),
				swapParams.deadline
			);
	}
}