// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @title ContractGuardian
 * @dev Helper contract to help protect against contract based mint spamming attacks.
 */
abstract contract ContractGuardian {
	modifier onlyUsers() {
		require(tx.origin == msg.sender, "Must be user");
		_;
	}
}