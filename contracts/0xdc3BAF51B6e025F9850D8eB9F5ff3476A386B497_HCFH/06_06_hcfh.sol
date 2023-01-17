// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract HCFH is ERC20, ERC20Burnable {
    constructor() ERC20("Humans Care Foundation: House", "HCFH") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}