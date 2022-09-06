// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import './WithLimitedSupply.sol';

/// @author Modified version of original code by 1001.digital
/// @title Randomly assign tokenIDs from a given set of tokens.
abstract contract RandomlyAssigned is WithLimitedSupply {
	// Used for random index assignment
	mapping(uint256 => uint256) private tokenMatrix;

	// The initial token ID
	uint256 private immutable startFrom;

	/// Instanciate the contract
	/// @param maxSupply_ how many tokens this collection should hold
	/// @param numReserved_ the number of tokens reserved whose IDs dont come from the randomizer
	constructor(uint256 maxSupply_, uint256 numReserved_)
		WithLimitedSupply(maxSupply_, numReserved_)
	{
		startFrom = numReserved_ + 1;
	}

	/// Get the next token ID
	/// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
	/// @return the next token ID
	function nextToken() internal override returns (uint256) {
		uint256 maxIndex = maxAvailableSupply() - tokenCount();
		uint256 random = uint256(
			keccak256(
				abi.encodePacked(
					msg.sender,
					block.coinbase,
					block.difficulty,
					block.gaslimit,
					block.timestamp
				)
			)
		) % maxIndex;

		uint256 value = 0;
		if (tokenMatrix[random] == 0) {
			// If this matrix position is empty, set the value to the generated random number.
			value = random;
		} else {
			// Otherwise, use the previously stored number from the matrix.
			value = tokenMatrix[random];
		}

		// If the last available tokenID is still unused...
		if (tokenMatrix[maxIndex - 1] == 0) {
			// ...store that ID in the current matrix position.
			tokenMatrix[random] = maxIndex - 1;
		} else {
			// ...otherwise copy over the stored number to the current matrix position.
			tokenMatrix[random] = tokenMatrix[maxIndex - 1];
		}

		// Increment counts (ie. qty minted)
		super.nextToken();

		return value + startFrom;
	}
}