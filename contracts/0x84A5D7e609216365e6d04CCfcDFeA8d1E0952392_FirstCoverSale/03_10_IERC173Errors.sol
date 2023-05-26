// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC173Errors {
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER(address operator);
}