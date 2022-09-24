// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/// @notice Probability that some result happens based on its shares
/// @notice The probability of getting results[0] is shares[0] / sum
/// @dev sum needs to be equal to the sum of shares
/// @dev the length of the shares and results arrays need to be equal
struct Probabilities {
	uint16 sum;
	uint8[] shares;
	uint16[] results;
}

library ProbabilitiesLib {
	function getRandomUint(Probabilities storage probabilities, uint256 random)
		internal
		view
		returns (uint16)
	{
		uint256 number = random % probabilities.sum;
		uint256 length = probabilities.shares.length;
		uint8 total = 0;

		for (uint8 i = 0; i < length; ) {
			unchecked {
				total += probabilities.shares[i];
			}

			if (number < total) {
				return probabilities.results[i];
			}

			unchecked {
				i++;
			}
		}

		revert('SHOULD_NOT_HAPPEN');
	}
}