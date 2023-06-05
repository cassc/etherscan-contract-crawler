// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library HoldersHelper {
	
	struct TokenHolders {
		address[] holders;
		mapping(address => uint256) holdersIndex;
	}

	function addHolder(TokenHolders storage tokenHolders, address newHolder) internal {
		tokenHolders.holders.push(newHolder);
		tokenHolders.holdersIndex[newHolder] = tokenHolders.holders.length;
	}

	function swapHolders(TokenHolders storage tokenHolders, address holder) internal {
		uint256 knownIndex = tokenHolders.holdersIndex[holder] - 1;
		uint256 knownLastIndex = tokenHolders.holders.length - 1;

		if (knownIndex != knownLastIndex) { 
			address knownLastAddress = tokenHolders.holders[knownLastIndex];

			tokenHolders.holders[knownIndex] = knownLastAddress;
			tokenHolders.holdersIndex[knownLastAddress] = knownIndex + 1;

			tokenHolders.holders[knownLastIndex] = holder;
			tokenHolders.holdersIndex[holder] = knownLastIndex + 1; 
		}
	}

	function removeHolder(TokenHolders storage tokenHolders, address holderToRemove) internal {
		tokenHolders.holdersIndex[holderToRemove] = 0; 
		tokenHolders.holders.pop();
	}
	
}