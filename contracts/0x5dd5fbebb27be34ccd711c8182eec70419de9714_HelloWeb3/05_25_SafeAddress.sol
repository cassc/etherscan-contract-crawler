// SPDX-License-Identifier: BSD-4-Clause
/*
 * Handles ensuring that the contract is being called by a user and not a contract.
 */
pragma solidity 0.8.4;

library SafeAddress {
	function isContract(address account) internal view returns (bool) {
		uint size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}
}