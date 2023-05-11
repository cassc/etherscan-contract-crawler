// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Pigcoin is ERC20, ERC20Burnable {
    constructor() ERC20("Pigcoin", "PIG") {
        _mint(msg.sender, 8888888888 * 10 ** decimals());
    }
}