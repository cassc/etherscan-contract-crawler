// SPDX-License-Identifier: MIT
/*


  ███▄ ▄███▓▓█████  ███▄ ▄███▓▓█████    ▄▄▄▄    ██▓     ▒█████   ▒█████  ▓█████▄  
 ▓██▒▀█▀ ██▒▓█   ▀ ▓██▒▀█▀ ██▒▓█   ▀   ▓█████▄ ▓██▒    ▒██▒  ██▒▒██▒  ██▒▒██▀ ██▌ 
 ▓██    ▓██░▒███   ▓██    ▓██░▒███     ▒██▒ ▄██▒██░    ▒██░  ██▒▒██░  ██▒░██   █▌ 
 ▒██    ▒██ ▒▓█  ▄ ▒██    ▒██ ▒▓█  ▄   ▒██░█▀  ▒██░    ▒██   ██░▒██   ██░░▓█▄   ▌ 
 ▒██▒   ░██▒░▒████▒▒██▒   ░██▒░▒████▒  ░▓█  ▀█▓░██████▒░ ████▓▒░░ ████▓▒░░▒████▓  
 ░ ▒░   ░  ░░░ ▒░ ░░ ▒░   ░  ░░░ ▒░ ░  ░▒▓███▀▒░ ▒░▓  ░░ ▒░▒░▒░ ░ ▒░▒░▒░  ▒▒▓  ▒  
 ░  ░      ░ ░ ░  ░░  ░      ░ ░ ░  ░  ▒░▒   ░ ░ ░ ▒  ░  ░ ▒ ▒░   ░ ▒ ▒░  ░ ▒  ▒  
 ░      ░      ░   ░      ░      ░      ░    ░   ░ ░   ░ ░ ░ ▒  ░ ░ ░ ▒   ░ ░  ░  
        ░      ░  ░       ░      ░  ░   ░          ░  ░    ░ ░      ░ ░     ░     
                                             ░                            ░       

*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blood is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Blood", "BLOOD") {
        _mint(msg.sender, 1_337_404_200 * 10**18);
    }
}