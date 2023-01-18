// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.10;

import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';

contract Config is Ownable {
  uint256 public defaultSlippage = 5000; // 0.5%

  uint256 public LTV = 6500; // 65%

  uint256 public roundingBuffer = 10000; // default 100% (0% rounding buffer) // buffer * 1e4

  // constructor() {}

  function setDefaultSlippage(uint256 s) public onlyOwner {
    defaultSlippage = s;
  }

  function setLTV(uint256 l) public onlyOwner {
    LTV = l;
  }

  function setRoundingBuffer(uint256 l) public onlyOwner {
    roundingBuffer = l;
  }
}