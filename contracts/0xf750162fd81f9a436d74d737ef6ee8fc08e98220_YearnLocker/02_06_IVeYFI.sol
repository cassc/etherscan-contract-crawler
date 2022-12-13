// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVeYFI {
	function modify_lock(
		uint256 amount,
		uint256 unlock_time,
		address user
	) external;

	struct LockedBalance {
		uint256 amount;
		uint256 end;
	}

	function balanceOf(address account) external view returns (uint256);

	function withdraw() external;

	function locked(address) external view returns (LockedBalance memory);
}