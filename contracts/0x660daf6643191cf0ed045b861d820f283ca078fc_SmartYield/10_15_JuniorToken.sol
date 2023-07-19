// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract JuniorToken is ERC20 {

    constructor(
      string memory name_,
      string memory symbol_,
      uint8 decimals_
    )
      ERC20(name_, symbol_)
    {
      _setupDecimals(decimals_);
    }

}