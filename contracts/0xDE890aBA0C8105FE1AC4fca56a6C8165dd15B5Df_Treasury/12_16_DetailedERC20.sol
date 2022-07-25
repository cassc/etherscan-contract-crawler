// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DetailedERC20 is ERC20 {
    
    // add custom decimals
    uint8 public _decimals;

    constructor(string memory _name, string memory _symbol, uint8 _underlyingDecimals) ERC20(_name, _symbol) {
        _decimals = _underlyingDecimals;
    }

   function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

}