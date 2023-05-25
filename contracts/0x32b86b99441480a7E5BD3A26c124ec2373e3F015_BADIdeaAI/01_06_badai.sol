// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BADIdeaAI is ERC20, ERC20Burnable {
    constructor() ERC20("BAD IDEA AI", "BAD") {
        _mint(msg.sender, 8310410598973273110117 * 10 ** (decimals() - 7));
    }
}