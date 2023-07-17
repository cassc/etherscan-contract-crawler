// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract FeudalzGoldz is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Feudalz Goldz", "GOLDZ") ERC20Permit("Feudalz Goldz") {
        _mint(msg.sender, 5_000_000 * 10 ** decimals());
    }
}