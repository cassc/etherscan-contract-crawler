// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { MasterChef } from "./MasterChef.sol";

contract Patch
{
	address constant MASTER_CHEF = 0x8BAB23A24430E82C9D384F2996e1671f3e64869a;
	address constant COUNTERPARTY_POOL = 0x3331CF717e3d89A09Cf75D2A76214C02373f4167;
	address constant PCS_XGRO_CVDC = 0x5768e385a03c5ac3D4050ca3D8be004f272B14E2;

	function run() external
	{
		uint256 _totalAllocPoint = 0;
		for (uint256 _i = 8; _i < 12; _i++) {
			(address _token, uint256 _allocPoint,,,,,,) = MasterChef(MASTER_CHEF).poolInfo(_i);
			require(_token == COUNTERPARTY_POOL, "invalid token");
			_totalAllocPoint += _allocPoint;
		}
		require(_totalAllocPoint == 10000000, "invalid alloc point");
		MasterChef(MASTER_CHEF).updateClusterAllocPoints(8, 0);
		MasterChef(MASTER_CHEF).addCluster(PCS_XGRO_CVDC, 10000000, block.timestamp);
	}
}