// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {PumpStorage} from "./PumpStorage.sol";

abstract contract PumpStorageExt is PumpStorage {
    


	// !!! Add new variable MUST append it only, do not insert, update type & name, or change order !!!
	// https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#potentially-unsafe-operations
    
    // For upgradable, add one new variable above, minus 1 at here
    uint[50] private __gap;
}