// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiBabydoge is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("AiBabydoge", "AiBabydoge") {
         _mint(0x5ef82A21e8a4199824093B27131fc50816fBbBDf, 1000000000*10**18);
    }
}