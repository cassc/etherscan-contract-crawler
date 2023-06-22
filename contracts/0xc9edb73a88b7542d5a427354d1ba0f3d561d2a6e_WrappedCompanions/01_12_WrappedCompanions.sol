// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './WrappedNoundlesTheory.sol';

contract WrappedCompanions is WrappedNoundlesTheory {
  constructor(address tokenAddress)
    WrappedNoundlesTheory('Wrapped Companions', 'WCOMPANIONS', 0, tokenAddress)
  {}
}