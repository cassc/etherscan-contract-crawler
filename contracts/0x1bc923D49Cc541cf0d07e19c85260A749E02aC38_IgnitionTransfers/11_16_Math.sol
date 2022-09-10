// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
* @title IGNITION Events Contract
* @author Edgar Sucre
* @notice This Library holdls math helper functions
*/
library Math {
    /**
	* @dev MulDiv standard function to handle the recommended order in solidity to perform arithmetic operations of multiplication and division
	* @param x The multiplicand
	* @param y The multiplier
	* @param z The denominator
	* @return the 256 result
	*/
	function muldiv(uint256 x, uint256 y, uint256 z)
	internal pure returns (uint256)
	{
		return x * y / z;
	}

	/**
	* @dev Calculates ceil(a×b÷denominator)
	* @param a The multiplicand
	* @param b The multiplier
	* @param denominator The divisor
	* @return result The 256-bit result
	*/
	function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator)
	internal pure returns (uint256) {
		uint256 result = muldiv(a, b, denominator);
		if (mulmod(a, b, denominator) > 0) {
			require(result < type(uint256).max);
			result++;
		}
		return result / 1e1;
	}
}