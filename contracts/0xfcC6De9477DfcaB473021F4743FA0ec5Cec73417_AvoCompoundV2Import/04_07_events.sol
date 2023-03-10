// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Events {
	event LogCompoundImport(
		address indexed user,
		address[] ctokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
}