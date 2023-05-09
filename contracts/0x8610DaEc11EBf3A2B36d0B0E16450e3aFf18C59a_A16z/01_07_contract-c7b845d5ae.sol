// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract A16z is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("a16z", "A16Z") {
        _mint(msg.sender, 16000000000 * 10 ** decimals());
    }
}