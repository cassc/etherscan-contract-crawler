// (c) Copyright 2022, Bad Pumpkin Inc. All Rights Reserved
//
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

/// @notice Square-root function for providing initial liquidity.
/// @dev    Sourced from Uniswap V2 library:
///           - https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
/// @dev    Based on Babylonian Method:
///           - https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
/// @param _value Is a number to approximate the square root of.
/// @return root The approximate square root of _value using the Babylonian Method.
///
// solhint-disable-next-line func-visibility
function sqrt(uint256 _value) pure returns (uint256 root) {
  if (_value > 3) {
    root = _value;
    uint256 iteration = _value / 2 + 1;
    while (iteration < root) {
      root = iteration;
      iteration = (_value / iteration + iteration) / 2;
    }
  } else if (_value != 0) {
    root = 1;
  }
}