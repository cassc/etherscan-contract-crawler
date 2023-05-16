// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract PugBucks is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("PugBucks", "PGB") {
        _mint(msg.sender, 131415926535 * 10 ** decimals());
    }
}