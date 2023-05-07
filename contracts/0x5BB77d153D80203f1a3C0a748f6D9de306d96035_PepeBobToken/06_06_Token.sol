// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepeBobToken is Ownable, ERC20 {

    constructor() ERC20("Pepe Bob", "PEBOB") {
        _mint(msg.sender, 4_206_969_696_969 * 10**uint(decimals()));
    }
}