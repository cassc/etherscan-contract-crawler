// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Website: https://www.therealxrp.xyz
// Twitter: https://www.twitter.com/therealxrp69
// Telegram: https://t.me/therealxrp

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract LebronJamesVapejuiceXRP69Inu is ERC20, Ownable {
    constructor() ERC20("LebronJamesVapejuiceXRP69Inu", "NICOTINE") {
        _mint(msg.sender, 4206900000000 * 10 ** decimals());
    }
}