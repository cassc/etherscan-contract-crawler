// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev ISmolGame interface
 */

interface ISmolGame {
  function getFinalServiceFeeWei() external view returns (uint256);

  function getBaseServiceFeeWei(uint256 costUSDCents)
    external
    view
    returns (uint256);
}