// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'src/interfaces/IERC20.sol';

// @https://github.com/wombex-finance/wombex-contracts/tree/main/contracts

interface IPoolDepositor {
	function lpTokenToPid(address _lpToken) external view returns (uint256 pid);

	function deposit(
		address _lpToken,
		uint256 _amount,
		uint256 _minLiquidity,
		bool _stake
	) external;

	function withdraw(
		address _lpToken,
		uint256 _amount,
		uint256 _minOut,
		address _recipient
	) external;
}

interface IAsset is IERC20 {
	function underlyingToken() external view returns (address);

	function pool() external view returns (address);
}

interface IBaseRewardPool is IERC20 {
	function getReward(address _account, bool _claimExtras) external returns (bool);
}

interface IBooster {
	function poolInfo(uint256 _pid)
		external
		view
		returns (
			address _lpToken,
			address _token,
			address _gauge,
			address _crvRewards,
			bool shutdown
		);
}