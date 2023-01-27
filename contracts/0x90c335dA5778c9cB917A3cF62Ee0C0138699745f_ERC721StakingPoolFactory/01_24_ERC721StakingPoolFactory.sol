// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { BaseStakingPoolFactory } from "./BaseStakingPoolFactory.sol";
import { ERC721StakingPool } from "./ERC721StakingPool.sol";

contract ERC721StakingPoolFactory is BaseStakingPoolFactory
{
	function _createPoolImpl() internal override returns (address _pool)
	{
		return address(new ERC721StakingPool(address(0), address(0)));
	}
}