// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IArrayErrors {
  /**
  * @dev Thrown when two related arrays have different lengths
  */
  error ARRAY_LENGTH_MISMATCH();
}