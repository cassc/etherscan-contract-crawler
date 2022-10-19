//Made with Student Coin Terminal
//SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWhitelist {
  function use(uint256) external returns (bool);
}