// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IFraxPoolRegistry {
	// Pool informations
	function poolInfo(
		uint256 _pid
	)
		external
		returns (
			address implementation,
			address stakingAddress,
			address stakingToken,
			address rewardsAddress,
			bool active
		);

	//pool -> user -> vault
	function vaultMap(uint256 _pid, address _acccount) external returns (address vault);
}