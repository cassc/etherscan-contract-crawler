// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { BaseStakingPoolFactory } from "./BaseStakingPoolFactory.sol";
import { NativeStakingPool } from "./NativeStakingPool.sol";

contract NativeStakingPoolFactory is BaseStakingPoolFactory
{
	function _createPoolImpl() internal override returns (address _pool)
	{
		return address(new NativeStakingPool(address(0)));
	}
}