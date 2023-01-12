// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "../types/Type.sol";
import "./Runo.sol";

contract RunoWorker is Runo {
  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseUri_
  ) Runo(name_, symbol_, baseUri_) {
    // tier 0 : CPU
    // tier 1 : GPU
    // tier 2 : HighGPU
    maxTier = 2;
    for (uint256 i = 0; i <= maxTier; i++) {
      tierSupplyCap[i] = 0;
      minTokenIds[i] = tierMaxCap * i + 1;
    }
    totalSupplyCap = 0;
  }
}