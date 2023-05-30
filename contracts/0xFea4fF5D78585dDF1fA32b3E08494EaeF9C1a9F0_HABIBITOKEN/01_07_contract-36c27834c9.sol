// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract HABIBITOKEN is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("HABIBI TOKEN", "HBT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}