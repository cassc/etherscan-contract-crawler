// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiBabydoge is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("AiBabydoge", "AiBabydoge") {
         _mint(0xb7C76189f7B262aa3CE253C99eD36F9aAbb50Dda, 1000000000*10**18);
    }
}