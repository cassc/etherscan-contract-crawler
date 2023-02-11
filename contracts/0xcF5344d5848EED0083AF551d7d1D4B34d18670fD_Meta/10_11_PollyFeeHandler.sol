// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract PollyFeeHandler {

  /// @dev get the fee for a given address and amount
  function get(
    address,
    uint value_
  )
  public pure returns (uint){
    if(value_ == 0)
      return 0;
    return (value_/100)*5;
  }

}