// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiquidManzana is ERC20 {
    constructor() ERC20("LiquidManzana", "LQDM") {
        _mint(msg.sender, 777000000 * 10 ** 18);
    }
    
}