// SPDX-License-Identifier: MIT45
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract TrumpToTheMoon is ERC20, ERC20Burnable, ERC20Permit, ERC20FlashMint, Ownable {
    constructor()
        ERC20("Trump to the moon", "TMT")
        ERC20Permit("Trump to the moon")
    {
        _mint(msg.sender, 450000000000000 * 10 ** decimals());
    }
}