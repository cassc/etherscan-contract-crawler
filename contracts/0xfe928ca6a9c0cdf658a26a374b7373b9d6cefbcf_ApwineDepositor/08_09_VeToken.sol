// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface VeToken {
	struct LockedBalance {
		int128 amount;
		uint256 end;
	}

	function create_lock(uint256 _value, uint256 _unlock_time) external;

	function increase_amount(uint256 _value) external;

	function increase_unlock_time(uint256 _unlock_time) external;

	function withdraw() external;

	function locked__end(address) external view returns (uint256);
}