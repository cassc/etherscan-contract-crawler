// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

abstract contract GasBaseFee {
  // internals
  function _gasPrice() internal view virtual returns (uint256) {
    return block.basefee;
  }
}