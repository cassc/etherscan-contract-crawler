// TELEGRAM https://t.me/TURBO_DUCK_ERC20

// TWITTER https://twitter.com/TURBO_DUCK_ETH

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract TURBODUCK is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor() ERC20("TURBO DUCK", "TURBO DUCK") ERC20Permit("TURBO DUCK") {
        _mint(msg.sender, 5000000000000 * 10 ** decimals());
    }
}