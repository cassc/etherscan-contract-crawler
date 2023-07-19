// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PEPE14ProMax is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("PEPE14ProMax token", "PEPE14ProMax") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}