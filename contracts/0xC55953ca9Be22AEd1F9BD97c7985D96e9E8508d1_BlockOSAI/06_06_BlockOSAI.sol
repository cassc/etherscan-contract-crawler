// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract BlockOSAI is ERC20, ERC20Burnable {
    constructor() ERC20("BlockOS AI", "BOSAI") {
        _mint(msg.sender, 5500000 * 10 ** decimals());
    }
}