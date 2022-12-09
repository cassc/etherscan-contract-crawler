// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract BlockDelay {
	/// @notice delay before functions with 'useBlockDelay' can be called by the same address
	/// @dev 0 means no delay
	uint256 public blockDelay;
	uint256 internal constant MAX_BLOCK_DELAY = 10;

	mapping(address => uint256) public lastBlock;

	error AboveMaxBlockDelay();
	error BeforeBlockDelay();

	constructor(uint8 _delay) {
		_setBlockDelay(_delay);
	}

	function _setBlockDelay(uint8 _newDelay) internal {
		if (_newDelay > MAX_BLOCK_DELAY) revert AboveMaxBlockDelay();
		blockDelay = _newDelay;
	}

	modifier useBlockDelay(address _address) {
		if (block.number < lastBlock[_address] + blockDelay) revert BeforeBlockDelay();
		lastBlock[_address] = block.number;
		_;
	}
}