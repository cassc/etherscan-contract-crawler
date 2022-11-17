// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../Interfaces/ISmartChef.sol';
import './BaseLaunchStrategy.sol';

/*
 * @dev Implementation of {BaseLaunchStrategy} abstract contract that does not earn any external yield
 */
contract NoEarnStrategy is BaseLaunchStrategy {
	constructor(
		address _masterTribe,
		IERC20 _stakedToken,
		IUniswapV2Router02 _router,
		address[] memory _stakingTokenOrLP0ToStable,
		address[] memory _stakingLP1ToStable,
		bool _stakedIsLp
	)
		BaseLaunchStrategy(
			_masterTribe,
			_stakedToken,
			_stakedToken,
			address(0),
			address(0),
			_router,
			_stakingTokenOrLP0ToStable,
			_stakingLP1ToStable,
			_stakedIsLp
		)
	{}

	/*
	 * @dev This method does nothing as this strategy does not earn
	 */
	function _depositToFarm(uint256 amount) internal override {}

	/*
	 * @dev This method does nothing as this strategy does not earn
	 */
	function _withdrawFromFarm(uint256 amount) internal override {}
}