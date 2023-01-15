// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract RandomHelp {
	uint256 private totalCount;
	uint256 private usedCount;
	mapping(uint256 => uint256) private randomPool;

	constructor(uint256 _totalCount) {
		totalCount = _totalCount;
	}

	function getRandomId(uint256 salt) internal returns (uint256 randomId) {
		require(usedCount < totalCount, "Quantity used out");
		uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, salt, usedCount)));
		randomId = getIndex(rand) + 1;
	}

	function getIndex(uint256 rand) internal returns (uint256) {
		uint256 lastCount = totalCount - usedCount;
		uint256 index = rand % lastCount;
		uint256 target = randomPool[index];
		uint256 pointIndex = target > 0 ? target : index;
		target = randomPool[--lastCount];
		randomPool[index] = target > 0 ? target : lastCount;
		usedCount++;
		return pointIndex;
	}
}