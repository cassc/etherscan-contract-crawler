// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.19;

interface INameWrapper {
  function unwrapETH2LD(bytes32 label, address newRegistrant, address newController) external;
}