// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBooster {
	function poolInfo(uint256 _pid)
		external
		view
		returns (
			address lpToken,
			address token,
			address gauge,
			address crvRewards,
			address stash,
			bool shutdown
		);

	function deposit(
		uint256 _pid,
		uint256 _amount,
		bool _stake
	) external returns (bool);

	function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
}