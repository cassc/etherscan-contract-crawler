// SPDX-License-Identifier: MIT
/**
Website
https://influencerdao.life	
Telegram
https://t.me/influencerdao
Twitter
https://twitter.com/InfluencerDAO_
*/
pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract INF is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("InfluencerDAO", "INF") {
        _mint(msg.sender,  100000000000 * (10 ** decimals())); 
    }
}