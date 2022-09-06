// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

import {IERC20} from './IERC20.sol';

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}