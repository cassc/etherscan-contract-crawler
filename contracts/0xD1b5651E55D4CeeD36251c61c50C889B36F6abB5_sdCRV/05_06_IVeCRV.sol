// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVeCRV {
	struct LockedBalance {
		int128 amount;
		uint256 end;
	}
	
	function locked(address) external returns(LockedBalance memory);
}