// SPDX-License-Identifier: MIT

/*

The official Pepe x Ledger collab community coin.

0% tax, LP burnt and contract renounced.

Telegram: https://t.me/PepeLedger
X: https://x.com/PeleERC
Website: https://PepeLedger.com


██████  ███████ ██      ███████ 
██   ██ ██      ██      ██      
██████  █████   ██      █████   
██      ██      ██      ██      
██      ███████ ███████ ███████ 


*/

pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact [email protected]
contract PepeLedger is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Pepe Ledger", "PELE") ERC20Permit("Pepe Ledger") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }
}