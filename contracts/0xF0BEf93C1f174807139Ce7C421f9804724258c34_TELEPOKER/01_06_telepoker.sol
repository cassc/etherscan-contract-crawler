/**
$TELEPOKER

Telepoker brings together the excitement of Texas Hold'em poker and the convenience of the Telegram messaging app. 
We aim to redefine mobile gaming by seamlessly integrating poker into Telegram, providing players with a user-friendly experience and introducing $TELEPOKER tokens to enhance gameplay. 

The Telepoker Vision is to create a vibrant poker community within Telegram, where players can enjoy poker with friends and make new connections. 
We strive to be at the forefront of the chat bot revolution, leveraging Telegram's platform to provide an engaging and accessible poker experience.

How Telepoker Works 
1. Registration and Profile Creation Players can easily register and create profiles within the Telepoker platform. 
2. Adding Friends and Networking  
3. Joining Tables and Inviting Friends
4. Top Friends Leaderboard

 ________  ________  __        ________  _______    ______   __    __  ________  _______  
|        \|        \|  \      |        \|       \  /      \ |  \  /  \|        \|       \ 
 \$$$$$$$$| $$$$$$$$| $$      | $$$$$$$$| $$$$$$$\|  $$$$$$\| $$ /  $$| $$$$$$$$| $$$$$$$\
   | $$   | $$__    | $$      | $$__    | $$__/ $$| $$  | $$| $$/  $$ | $$__    | $$__| $$
   | $$   | $$  \   | $$      | $$  \   | $$    $$| $$  | $$| $$  $$  | $$  \   | $$    $$
   | $$   | $$$$$   | $$      | $$$$$   | $$$$$$$ | $$  | $$| $$$$$\  | $$$$$   | $$$$$$$\
   | $$   | $$_____ | $$_____ | $$_____ | $$      | $$__/ $$| $$ \$$\ | $$_____ | $$  | $$
   | $$   | $$     \| $$     \| $$     \| $$       \$$    $$| $$  \$$\| $$     \| $$  | $$
    \$$    \$$$$$$$$ \$$$$$$$$ \$$$$$$$$ \$$        \$$$$$$  \$$   \$$ \$$$$$$$$ \$$   \$$
                                                                                          
GAME:    https://telepoker.tech
INFO:    https://telepoker.tech/wp-content/uploads/2023/09/Whitepaper.pdf

PORTAL:  https://t.me/TelepokerPortal                                                                                         
TWITTER: https://twitter.com/Telepoker_                                                                                          

**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TELEPOKER is ERC20 {
    constructor() ERC20("Telepoker", "TELEPOKER") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}