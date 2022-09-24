// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Custom
import { ProbabilitiesLib, Probabilities } from './ProbabilitiesLib.sol';

// Libraries
using ProbabilitiesLib for Probabilities;

abstract contract Randomness {
	uint256 seed;

	constructor() {
		initRandom();
	}

	function initRandom() private {
		seed = uint256(
			keccak256(
				abi.encodePacked(
					blockhash(block.number - 1),
					block.coinbase,
					block.difficulty
				)
			)
		);
	}

	function getRandom() internal returns (uint256 random) {
		seed = uint256(
			keccak256(
				abi.encodePacked(
					seed,
					blockhash(block.number - ((seed % 63) + 1)),
					block.coinbase,
					block.difficulty
				)
			)
		);
		return seed;
	}

	function getRandomUint(Probabilities storage probabilities)
		internal
		returns (uint16)
	{
		return probabilities.getRandomUint(getRandom());
	}
}