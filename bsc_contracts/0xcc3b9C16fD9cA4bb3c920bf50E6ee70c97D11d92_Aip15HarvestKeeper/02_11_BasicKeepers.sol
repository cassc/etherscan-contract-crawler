// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/
pragma solidity 0.8.12;

import { Ownable } from "./Ownable.sol";

// solhint-disable not-rely-on-time
abstract contract BasicKeepers is Ownable {
  string public name;

  constructor(string memory _name) {
    name = _name;
    _transferOwnership(msg.sender);
  }
}
