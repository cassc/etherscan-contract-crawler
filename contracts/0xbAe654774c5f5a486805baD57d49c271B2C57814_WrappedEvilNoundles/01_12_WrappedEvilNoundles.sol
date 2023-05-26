// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './WrappedNoundlesTheory.sol';

contract WrappedEvilNoundles is WrappedNoundlesTheory {
  constructor(address tokenAddress)
    WrappedNoundlesTheory(
      'Wrapped Evil Noundles',
      'WEVILNOUNDLES',
      1,
      tokenAddress
    )
  {}
}