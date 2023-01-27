// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { BaseStakingPoolFactory } from "./BaseStakingPoolFactory.sol";
import { ERC1155StakingPool } from "./ERC1155StakingPool.sol";

contract ERC1155StakingPoolFactory is BaseStakingPoolFactory
{
	function _createPoolImpl() internal override returns (address _pool)
	{
		return address(new ERC1155StakingPool(address(0), address(0)));
	}
}