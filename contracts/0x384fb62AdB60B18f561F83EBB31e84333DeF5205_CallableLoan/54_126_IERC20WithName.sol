// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard along with the "name()" function.
 */
interface IERC20WithName is IERC20 {
  function name() external view returns (string memory);
}