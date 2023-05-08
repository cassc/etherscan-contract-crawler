// SPDX-License-Identifier: MIT                                                                                    

// Telegram : t.me/JordanCoinERC
// Twitter  : twitter.com/JordanCoinERC
// Website  : jordan-erc.com


pragma solidity ^0.8.9;


import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";


contract Jordan is ERC20, Ownable {
   constructor() ERC20("Jordan", "JORDAN") {
       _mint(msg.sender, 23000000000 * 10 ** decimals());
   }
}