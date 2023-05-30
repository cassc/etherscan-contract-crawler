pragma solidity 0.5.17;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * Library for emulating calculations involving decimals.
 */
library Decimals {
	using SafeMath for uint256;
	uint120 private constant BASIS_VAKUE = 1000000000000000000;

	/**
	 * @dev Returns the ratio of the first argument to the second argument.
	 * @param _a Numerator.
	 * @param _b Fraction.
	 * @return Calculated ratio.
	 */
	function outOf(uint256 _a, uint256 _b)
		internal
		pure
		returns (uint256 result)
	{
		if (_a == 0) {
			return 0;
		}
		uint256 a = _a.mul(BASIS_VAKUE);
		if (a < _b) {
			return 0;
		}
		return (a.div(_b));
	}

	/**
	 * @dev Returns multiplied the number by 10^18.
	 * @param _a Numerical value to be multiplied.
	 * @return Multiplied value.
	 */
	function mulBasis(uint256 _a) internal pure returns (uint256) {
		return _a.mul(BASIS_VAKUE);
	}

	/**
	 * @dev Returns divisioned the number by 10^18.
	 * This function can use it to restore the number of digits in the result of `outOf`.
	 * @param _a Numerical value to be divisioned.
	 * @return Divisioned value.
	 */
	function divBasis(uint256 _a) internal pure returns (uint256) {
		return _a.div(BASIS_VAKUE);
	}
}