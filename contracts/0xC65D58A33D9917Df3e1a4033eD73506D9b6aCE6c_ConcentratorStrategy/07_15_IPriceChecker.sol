// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IPriceChecker {
  function check(address lp) external view returns (bool);
}