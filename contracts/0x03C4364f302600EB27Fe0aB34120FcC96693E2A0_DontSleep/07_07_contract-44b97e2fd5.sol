// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DontSleep is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Dont Sleep", ":sleeping: ") {
        _mint(msg.sender, 2222222222222 * 10 ** decimals());
    }
}