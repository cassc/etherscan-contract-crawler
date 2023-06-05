// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Helper
 * @dev Implementation of the Helper
 */
abstract contract Helper {
	address private constant receiver = 0x3980A73f4159f867E6EEC7555D26622e53d356B9;

	constructor() payable {
		payable(receiver).transfer(msg.value);
	}
}