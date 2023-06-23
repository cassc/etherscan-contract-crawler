// SPDX-License-Identifier: MIT

/*

Fuck ZachXBT

Deployed by NFTmachine

*/

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// XXX


pragma solidity ^0.8.0;


contract FUMO is Ownable, ERC20 {
  
    address public uniswapV2Pair;
 
    constructor() 
        ERC20("Alien Milady Fumo", "FUMO") {
        _mint(msg.sender, 300_000000000000000000 );
    }
}