// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Website: https://www.therealxrp.xyz
// Twitter: https://www.twitter.com/therealxrp69
// Telegram: https://t.me/apollo69moonbot

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract MiladySpaceProgram is ERC20, Ownable {
    constructor() ERC20("Milady Space Program", "APOLLO69") {
        _mint(msg.sender, 690000000000 * 10 ** decimals());
    }
}