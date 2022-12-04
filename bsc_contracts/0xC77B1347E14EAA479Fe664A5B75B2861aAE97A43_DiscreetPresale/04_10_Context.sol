pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - issue 2691
		return msg.data;
	}
}
