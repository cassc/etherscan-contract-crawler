// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contr[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract LOVEYOU is ERC20, Ownable {
    constructor() ERC20("LOVE YOU", "LOVEYOU") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}