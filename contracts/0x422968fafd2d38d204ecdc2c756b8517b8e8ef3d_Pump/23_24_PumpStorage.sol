// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {DataTypes} from "./lib/DataTypes.sol";

abstract contract PumpStorage {
	// !!! Add new variable MUST append it only, do not insert, update type & name, or change order !!!
	// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#potentially-unsafe-operations

	address public dga;


    uint public lockPeriod;
    uint public PumpRateMin;
    uint public PumpRateMax;
    uint public PumpStep;
    uint public PumpHill;

    mapping(address => DataTypes.BoostItem[]) public boosted;
    mapping(address => uint) public boostedNo;
    uint public totalNo;


	// !!! Never add new variable at here, because this contract is inherited by MyStorage !!!
	// !!! Add new variable at MyStorage directly !!!
}