// SPDX-License-Identifier: MIT
 
//      /$$$$$ /$$$$$$ /$$$$$$$ /$$$$$$$  /$$$$$$ /$$   /$$       /$$$$$$$$/$$$$$$$  /$$$$$$ 
//     |__  $$/$$__  $| $$__  $| $$__  $$/$$__  $| $$$ | $$      | $$_____| $$__  $$/$$__  $$
//        | $| $$  \ $| $$  \ $| $$  \ $| $$  \ $| $$$$| $$      | $$     | $$  \ $| $$  \__/
//        | $| $$  | $| $$$$$$$| $$  | $| $$$$$$$| $$ $$ $$/$$$$$| $$$$$  | $$$$$$$| $$      
//   /$$  | $| $$  | $| $$__  $| $$  | $| $$__  $| $$  $$$|______| $$__/  | $$__  $| $$      
//  | $$  | $| $$  | $| $$  \ $| $$  | $| $$  | $| $$\  $$$      | $$     | $$  \ $| $$    $$
//  |  $$$$$$|  $$$$$$| $$  | $| $$$$$$$| $$  | $| $$ \  $$      | $$$$$$$| $$  | $|  $$$$$$/
//   \______/ \______/|__/  |__|_______/|__/  |__|__/  \__/      |________|__/  |__/\______/ 
                                                                                         

// Telegram: t.me/JordanERC
// Twitter : twitter.com/Jordan_ERC


pragma solidity ^0.8.9;


import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";


contract Jordan is ERC20, Ownable {
   constructor() ERC20("Jordan", "JORDAN") {
       _mint(msg.sender, 23000000000000 * 10 ** decimals());
   }
}