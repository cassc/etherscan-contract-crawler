// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibQRNG} from "./LibQRNG.sol";

abstract contract WithAirnodeRrp {
  error OnlyAirnodeRrp();

  modifier onlyAirnodeRrp() {
    if (msg.sender != LibQRNG.DS().airnodeRrp) revert OnlyAirnodeRrp();
    _;
  }
}