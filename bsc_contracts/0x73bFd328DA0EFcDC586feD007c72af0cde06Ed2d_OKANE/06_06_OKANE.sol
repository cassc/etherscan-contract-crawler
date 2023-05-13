// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OKANE is ERC20, Ownable {
    constructor(uint256 amount,address to) ERC20("OKANE", "OKN") {
         _mint(to, amount);
    }
}