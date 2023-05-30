// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import './StrategyCompound.sol';

contract UsdcStrategyCompound is StrategyCompound {
	constructor(
		Vault _vault,
		address _treasury,
		address _nominatedOwner,
		address _admin,
		address[] memory _authorized,
		Swap _swap
	)
		StrategyCompound(
			_vault,
			_treasury,
			_nominatedOwner,
			_admin,
			_authorized,
			_swap,
			0x39AA39c021dfbaE8faC545936693aC917d5E7563
		)
	{}
}