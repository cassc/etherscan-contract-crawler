// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JessicaRabbit is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Jessica Rabbit", "JEXXX") {
        _mint(msg.sender, 696969696969 * 10 ** decimals());
    }
}