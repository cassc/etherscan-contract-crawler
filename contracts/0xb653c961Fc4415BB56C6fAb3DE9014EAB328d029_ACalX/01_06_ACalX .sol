// AstroCalciumX $ACalX

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ACalX is ERC20 { 
    constructor() ERC20("AstroCalciumX", "ACalX") { 
        _mint(msg.sender, 420_690_000 * 10**18);
    }
}