// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev ISmolGameFeeAdjuster interface
 */

interface ISmolGameFeeAdjuster {
  function getFinalServiceFeeWei(uint256 _baseFeeWei)
    external
    view
    returns (uint256);
}