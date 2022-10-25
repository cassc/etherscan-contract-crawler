// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library Router {
  function path(address a, address b) internal pure returns (address[] memory pathOut) {
    pathOut = new address[](2);
    pathOut[0] = a;
    pathOut[1] = b;
  }

  function path(
    address a,
    address b,
    address c
  ) internal pure returns (address[] memory pathOut) {
    pathOut = new address[](3);
    pathOut[0] = a;
    pathOut[1] = b;
    pathOut[2] = c;
  }
}