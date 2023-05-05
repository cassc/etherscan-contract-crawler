// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC2981Errors {
  /**
  * @dev Thrown when the desired royalty rate is higher than 10,000
  * 
  * @param royaltyRate the desired royalty rate
  * @param royaltyBase the maximum royalty rate
  */
  error IERC2981_INVALID_ROYALTIES(uint256 royaltyRate, uint256 royaltyBase);
}