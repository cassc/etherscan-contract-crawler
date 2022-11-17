// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import './MasterXFinance.sol';

contract MintMasterXFinance is MasterXFinance {
	constructor(
		IERC20Metadata _rewardToken,
		uint256 _rewardPerBlock,
		uint256 _startBlock,
		uint256 _bonusEndBlock,
		IUniswapV2Router02 _router,
		address[] memory _rewardToStablePath
	)
		MasterXFinance(
			_rewardToken,
			_rewardPerBlock,
			_startBlock,
			_bonusEndBlock,
			_router,
			_rewardToStablePath
		)
	{}

	/*
	 * @dev This method mints reward tokens as a way to fund farms
	 */
	function _fundRewardTokens(address recipient, uint256 amount)
		internal
		override
	{
		IMintableToken(address(rewardToken)).mint(recipient, amount);
	}
}