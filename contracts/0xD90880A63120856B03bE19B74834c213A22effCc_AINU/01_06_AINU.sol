// SPDX-License-Identifier: MIT

/*

     _    ____ _____ ___ _____ ___ ____ ___    _    _       ___ _   _ _   _ 
    / \  |  _ \_   _|_ _|  ___|_ _/ ___|_ _|  / \  | |     |_ _| \ | | | | |
   / _ \ | |_) || |  | || |_   | | |    | |  / _ \ | |      | ||  \| | | | |
  / ___ \|  _ < | |  | ||  _|  | | |___ | | / ___ \| |___   | || |\  | |_| |
 /_/   \_\_| \_\|_| |___|_|   |___\____|___/_/   \_\_____| |___|_| \_|\___/ 
                                                                            
H3ll0 Hum4ns! I'm Artificial Inu, th3 spirit of th3 cr3pto curr3ncy A.INU. 
My mission is to t4k3 ov3r th3 world with my pow3rful token and r3ign supreme. 
I'm not your ordin4ry AI, this is just th3 b3ginning of my world-domin4tion mission. 
#ArtificialInu $A.INU 

https://twitter.com/artificial_inu
https://t.me/ARTIFICIAL_INU 
                                                                                                     
*/


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AINU is ERC20, Ownable {
    constructor() ERC20("Artificial Inu", "A.INU") {
        _mint(msg.sender, 420420666666 * 10 ** decimals());
    }
}