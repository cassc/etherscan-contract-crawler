// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*


▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▓  ██████ ▄▄▄█████▓
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██▒▒██    ▒ ▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▒██▒░ ▓██▄   ▒ ▓██░ ▒░
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ░██░  ▒   ██▒░ ▓██▓ ░ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██░▒██████▒▒  ▒██▒ ░ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░   
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░ ▒ ░░ ░▒  ░ ░    ░    
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░    ▒ ░░  ░  ░    ░      
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░ ░        ░           
                                                                

            ;`.                       ,'/
            |`.`-.      _____      ,-;,'|
            |  `-.\__,-'     `-.__//'   |
            |     `|               \ ,  |
            `.  ```                 ,  .'
              \_`      \     /      `_/
                \    ^  \   /   ^   /
                 |   X   ____   X  |
                 |     ,'    `.    |
                 |    (  O' O  )   |
                 `.    \__,.__/   ,'
                   `-._  `--'  _,'
                       `------'

created with curiosity by .pwa group 2021.

    gm. wgmi.

            if you're reading this, you are early.

*/

import "./ERC721Custom.sol";        //Custom ERC721 implementation
import "./Base/Pausable.sol";       //Pause critical functions

contract TokenBank is Pausable, ERC721 {

    uint16 public constant MAX_BANKS = 1250;

    constructor() ERC721(
        "The Heist Banks",
        "BANK",
        MAX_BANKS)
    {
        //wgmi
    }

    function Mint(uint8 amount, address to) external onlyControllers whenNotPaused {
        for (uint256 i = 0; i < amount; i++ ){
            _mint(to, _totalMinted + 1); //start at tokenID = 1
        }
    }
    
}