// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.15;

// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
// Subject to the MIT license.

library BmallMath {
  uint256 internal constant UNIFIEDPOINT = 10 ** 18;
	/******************** Safe Math********************/
  function underlyingToUnifiedAmount(uint256 underlyingAmount, uint256 underlyingDecimal) internal pure returns (uint256) {
    return (underlyingAmount * UNIFIEDPOINT) / underlyingDecimal;
  }

  function unifiedToUnderlyingAmount(uint256 unifiedTokenAmount, uint256 underlyingDecimal) internal pure returns (uint256) {
    return (unifiedTokenAmount * underlyingDecimal) / UNIFIEDPOINT;
  }

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
	  return (a * UNIFIEDPOINT) / b;
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / UNIFIEDPOINT;
	}
}