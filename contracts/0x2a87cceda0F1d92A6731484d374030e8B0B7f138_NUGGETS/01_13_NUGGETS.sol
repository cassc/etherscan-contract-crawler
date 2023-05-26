// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract NUGGETS is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("NUGGETS", "NIKJ") ERC20Permit("NUGGETS") {
        _mint(msg.sender, 3000000000 * 10**decimals());
    }
}