// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";

/*
   .--.
  |o_o |
  |:_/ |
//   \ \  
(|     | )  
'/_'|_'\

 /$$$$$$$                               /$$$$$$$                                         /$$          
| $$__  $$                             | $$__  $$                                       |__/          
| $$  \ $$ /$$$$$$   /$$$$$$   /$$$$$$ | $$  \ $$ /$$$$$$  /$$$$$$$   /$$$$$$  /$$   /$$ /$$ /$$$$$$$ 
| $$$$$$$//$$__  $$ /$$__  $$ /$$__  $$| $$$$$$$//$$__  $$| $$__  $$ /$$__  $$| $$  | $$| $$| $$__  $$
| $$____/| $$$$$$$$| $$  \ $$| $$$$$$$$| $$____/| $$$$$$$$| $$  \ $$| $$  \ $$| $$  | $$| $$| $$  \ $$
| $$     | $$_____/| $$  | $$| $$_____/| $$     | $$_____/| $$  | $$| $$  | $$| $$  | $$| $$| $$  | $$
| $$     |  $$$$$$$| $$$$$$$/|  $$$$$$$| $$     |  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$/| $$| $$  | $$
|__/      \_______/| $$____/  \_______/|__/      \_______/|__/  |__/ \____  $$ \______/ |__/|__/  |__/
                   | $$                                              /$$  \ $$                        
                   | $$                                             |  $$$$$$/                        
                   |__/                                              \______/                         

PepePenguin ($PP) Launch!

Launching on 4/20, PepePenguin is here to Make Memes Great Again (MMGA)! Join the MMGA movement and slide 
into the future of the bigglest meme token, owned and driven by the community, as a meme coin should be.
No tax, no games, no CEX's, no BS, just yuge and bigly classy memes! Don't miss out on the revolution!

@PPepe_Penguin
https://mmgapepepenguin.com/

*/

contract PepePenguin is ERC20 {
    uint256 public constant SUPPLY = 420_690_420 * (10 ** 18);
    constructor() ERC20("PepePenguin", "PP", 18) {
        _mint(msg.sender, SUPPLY);
    }
}