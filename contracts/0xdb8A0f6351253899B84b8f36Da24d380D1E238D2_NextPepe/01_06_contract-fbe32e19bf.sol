// SPDX-License-Identifier: MIT
/*

Web: https://nextpepe.xyz/
Twitter: https://twitter.com/NextPepe
Telegram: https://t.me/Next_Pepe

*/    
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract NextPepe is ERC20, ERC20Burnable {
    constructor() ERC20("NextPepe", "NEXTPEPE") {
        _mint(msg.sender, 69420710666 * 11 ** 18);
    }
}