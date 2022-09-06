// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

interface IPairWithOverlay {
  function initialize(address _token0, address _token1, address _weth) external;
}