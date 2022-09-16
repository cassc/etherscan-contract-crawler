// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './ISmoltingInu.sol';

/**
 * @dev SmoltingInu token interface with decimals
 */

interface ISmoltingInuDecimals is ISmoltingInu {
  function decimals() external view returns (uint8);
}