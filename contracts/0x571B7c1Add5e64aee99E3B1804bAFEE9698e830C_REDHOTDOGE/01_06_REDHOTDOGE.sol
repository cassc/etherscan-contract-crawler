/*

Igniting the Future of
Cryptocurrency
Red Hot Doge is a groundbreaking cryptocurrency project that embodies the passion, humor. 
Boundless possibilities of the digital currency world. 

Inspired by the sensational rise of RedHotCock Token and fueled by the fervor of the crypto community, 
Red Hot Doge aspires to redefine the crypto landscape with its unique blend of excitement, innovation, and community-driven spirit.


Website: https://redhotdoge.com/
X: https://twitter.com/RED_HOT_DOGE
Telegram: https://t.me/REDHOTDOGEPortal

*/




// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract REDHOTDOGE is ERC20 { 
    constructor() ERC20("RED HOT DOGE", "RHD") { 
        _mint(msg.sender, 1_400_000_000 * 10**18);
    }
}