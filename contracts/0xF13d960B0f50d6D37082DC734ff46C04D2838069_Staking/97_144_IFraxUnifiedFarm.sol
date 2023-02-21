// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// solhint-disable var-name-mixedcase
interface IFraxUnifiedFarm {
	// Struct for the stake
	struct LockedStake {
		bytes32 kek_id;
		uint256 start_timestamp;
		uint256 liquidity;
		uint256 ending_timestamp;
		uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
	}

	// Total locked liquidity / LP tokens
	function lockedLiquidityOf(address account) external view returns (uint256);

	// All the locked stakes for a given account
	function lockedStakesOf(address account) external view returns (LockedStake[] memory);
}