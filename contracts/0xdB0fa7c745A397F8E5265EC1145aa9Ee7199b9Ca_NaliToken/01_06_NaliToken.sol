// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract NaliToken is ERC20, ERC20Burnable {
    constructor() ERC20("Nali Project", "NALI") {
        _mint(msg.sender, 14500 * 10 ** decimals());
    }
}