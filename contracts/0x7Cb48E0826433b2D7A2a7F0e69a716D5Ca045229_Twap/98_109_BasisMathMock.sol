// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../BasisMath.sol";

contract BasisMathMock {
  using BasisMath for uint256;

  function _splitBy(uint256 value, uint256 percentage)
    public
    pure
    returns (uint256, uint256)
  {
    return value.splitBy(percentage);
  }
}