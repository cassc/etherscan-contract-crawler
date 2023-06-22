// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";

interface IwstETH {
  function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);

  function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
}

/*****************************************
 *
 * This relay gets a USD price for wstETH using the direct conversion from the wstETH contract
 * and comparing to a known safe price for stETH
 */

contract wstETHRelay is IOracleRelay {
  IOracleRelay public constant stETH_Oracle = IOracleRelay(0x73052741d8bE063b086c4B7eFe084B0CEE50677A);

  IwstETH public wstETH = IwstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);

  function currentValue() external view override returns (uint256) {
    uint256 conversionRate = wstETH.getStETHByWstETH(1e18);

    uint256 stETH_Price = stETH_Oracle.currentValue();

    return (stETH_Price * conversionRate) / 1e18;
  }
}