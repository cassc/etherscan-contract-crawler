// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { BaseStakingPoolFactory } from "./BaseStakingPoolFactory.sol";
import { ERC20StakingPool } from "./ERC20StakingPool.sol";

contract ERC20StakingPoolFactory is BaseStakingPoolFactory
{
	function _createPoolImpl() internal override returns (address _pool)
	{
		return address(new ERC20StakingPool(address(0), address(0)));
	}
}