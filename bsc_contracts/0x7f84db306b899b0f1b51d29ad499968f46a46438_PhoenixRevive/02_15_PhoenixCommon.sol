// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./interfaces/ISwapRouter02.sol";
import "./OwnableUpgrade.sol";

abstract contract PhoenixCommon is OwnableUpgrade {
  ISwapRouter02 internal _router;
  address internal _currency;
  address[] internal _pathBuy;
  address[] internal _pathSell;
  address internal _pair;

  function __PhoenixCommon_init() internal onlyInitializing {
    __OwnableUpgrade_init();
  }

  function _isUser(address addr) internal view returns (bool) {
    return addr != NULL_ADDRESS && addr != _pair && addr != address(_router) && addr != _contractAddress && addr != _otherAddr;
  }
}