// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract A1 is ERC20, Ownable {
    constructor() ERC20("A1", "A1") {
        _mint(0x53214879Ad12c600e9c7d01539BEF3EC695a884d, 1 * 10 ** decimals());
        _mint(
            0x665F863f3b60d97a0EfAA0E10E34f24Fc1A38BBB,
            (10000000 - 1) * 10 ** decimals()
        );
    }
}