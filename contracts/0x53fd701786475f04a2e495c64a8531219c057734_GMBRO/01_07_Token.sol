/*
Telegram
https://t.me/GMBROPortal	
Website
https://gmbro.gay/	
Twitter
https://twitter.com/GMBRO_
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract GMBRO is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 _totalSupply) ERC20("GMBRO", "GMBRO") {
    _mint(msg.sender, _totalSupply);
    }

}