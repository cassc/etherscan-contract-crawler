// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20FlashMint.sol";

/// @custom:security-contact [email protected]
contract PoorPleb is ERC20, ERC20Burnable, ERC20FlashMint {
    constructor() ERC20("PoorPleb", "PP") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}