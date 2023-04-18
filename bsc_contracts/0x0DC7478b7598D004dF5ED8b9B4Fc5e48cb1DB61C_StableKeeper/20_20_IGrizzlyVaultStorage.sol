// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

interface IGrizzlyVaultStorage {
	// Needed to avoid error compiler stack too deep
	struct LocalVariablesBurn {
		uint256 totalSupply;
		uint256 liquidityBurnt;
		int256 amount0Delta;
		int256 amount1Delta;
	}

	struct Ticks {
		int24 lowerTick;
		int24 upperTick;
	}

	struct LocalVariablesPosition {
		uint128 liquidity;
		uint256 feeGrowthInside0Last;
		uint256 feeGrowthInside1Last;
		uint128 tokensOwed0;
		uint128 tokensOwed1;
	}

	function initialize(
		string memory _name,
		string memory _symbol,
		address _pool,
		uint24 _treasuryFee,
		int24 _lowerTick,
		int24 _upperTick,
		address _manager
	) external;
}