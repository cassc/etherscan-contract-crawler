/** 
Don't Buy Pepe
webs : https://dontbuypepe.com
tg   : https://t.me/DontBuyPepeOfficialPortal
twt  : https://twitter.com/DontBuyPepe_

Explore The Future With DBP
And A Game As Addictive As Crack
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DBP is ERC20 { 
    constructor() ERC20("Don't Buy Pepe", "DBP") { 
        _mint(msg.sender, 420_690_000_000 * 10**18);
    }
}