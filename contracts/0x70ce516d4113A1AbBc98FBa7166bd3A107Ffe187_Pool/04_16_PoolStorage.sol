// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {DataTypes} from "./libraries/DataTypes.sol";

contract PoolStorage {
	// maps underlying asset address to reserve struct
	mapping(address => DataTypes.Reserve) internal _reserves;
	// addresses of underlying assets
	address[] internal _reservesList;
	uint _repayPeriod;
}