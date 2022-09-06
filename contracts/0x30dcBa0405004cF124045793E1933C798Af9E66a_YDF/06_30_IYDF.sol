// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 * @dev YDF token interface
 */

interface IYDF is IERC20 {
  function addToBuyTracker(address _user, uint256 _amount) external;

  function burn(uint256 _amount) external;

  function stakeMintToVester(uint256 _amount) external;
}