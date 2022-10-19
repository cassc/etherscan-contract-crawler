// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {DataTypes} from "./DataTypes.sol";

library ReserveLogic {
	using ReserveLogic for DataTypes.Reserve;

	function init(
		DataTypes.Reserve storage reserve,
		address thTokenAddress
	) internal {
		reserve.thTokenAddress = thTokenAddress;
	}
}