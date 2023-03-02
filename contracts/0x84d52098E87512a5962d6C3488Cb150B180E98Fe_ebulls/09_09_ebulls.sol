// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract ebulls is ERC20, ERC20FlashMint, Ownable {
    constructor() ERC20("ebulls", "ebulls") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}