// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheBitGold is ERC20, Ownable {
    constructor(address to_) ERC20("TheBitGold", "BGT") {
        _mint(to_, 10000000 * 10 ** decimals());
    }
}