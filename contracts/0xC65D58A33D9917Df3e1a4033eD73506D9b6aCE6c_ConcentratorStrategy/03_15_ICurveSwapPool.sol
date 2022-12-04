// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// solhint-disable func-name-mixedcase

interface ICurveSwapPool {
  function get_virtual_price() external view returns (uint256);
}