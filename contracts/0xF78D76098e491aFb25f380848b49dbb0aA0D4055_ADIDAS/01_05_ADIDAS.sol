/**



 █████  ██████  ██ ██████   █████  ███████ 
██   ██ ██   ██ ██ ██   ██ ██   ██ ██      
███████ ██   ██ ██ ██   ██ ███████ ███████ 
██   ██ ██   ██ ██ ██   ██ ██   ██      ██ 
██   ██ ██████  ██ ██████  ██   ██ ███████ 
                                           
                                           





*/








// forked from APE coin \\
// well.. kinda.. \\
// just a simple no fee no bs token.. \\







// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ADIDAS is ERC20 {
    constructor() ERC20("ADIDAS", "ADIDAS") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}