// https://bingchilling.day
// https://t.me/bingchillingerc20	
// https://www.youtube.com/shorts/AWOyEIuVzzQ

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract BingChilling is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 _totalSupply) ERC20("Bing Chilling", "BINGQILIN") {
    _mint(msg.sender, _totalSupply);
    }

}