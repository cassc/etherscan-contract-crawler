// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AdonisCoin is ERC20, Ownable {
    constructor() ERC20("Adonis", "ADONIS") {
        _mint(0xD596B8ad400e3E93EaaF1814508dDE989a96F1f7, 420069000000 * 10 ** decimals());
    }
}