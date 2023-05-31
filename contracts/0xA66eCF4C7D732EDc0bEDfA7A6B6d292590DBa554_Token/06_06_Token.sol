// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    constructor() ERC20("UP ONLY", "UP") {
        _mint(0xF564b5984E5CE92f65A73B042c345CE52212d092, 100000000 * 10 ** decimals());
        transferOwnership(0xF564b5984E5CE92f65A73B042c345CE52212d092);
    }
}

// HELLO