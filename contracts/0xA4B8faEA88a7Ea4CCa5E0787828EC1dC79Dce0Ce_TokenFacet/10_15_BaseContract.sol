// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LibDiamond.sol";
import "./AppStorage.sol";

abstract contract BaseContract {
	function getState()
		internal pure returns (AppStorage.State storage s)
	{
		return AppStorage.getState();
	}
	
	modifier onlyOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}

}