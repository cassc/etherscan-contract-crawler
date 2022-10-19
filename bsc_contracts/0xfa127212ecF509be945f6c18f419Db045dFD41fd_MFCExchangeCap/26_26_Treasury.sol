// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../lib/token/BEP20/BEP20.sol";
import "../lib/utils/Context.sol";

contract Treasury is Context {

  BEP20 private _token;

  constructor(address tokenContractAddress_) {
    _token = BEP20(tokenContractAddress_);
  }

  function getTreasuryToken() internal view returns (BEP20) {
    return _token;
  }
}