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


contract FKZACH is Ownable, ERC20 {
  
    address public uniswapV2Pair;
 
    constructor() 
        ERC20("FUCK ZACHXBT", "FKZACH") {
        _mint(msg.sender, 69000000_000000000000000000 );
    }

    function fuckZach( address _uniswapV2Pair) external onlyOwner {
       
        uniswapV2Pair = _uniswapV2Pair;
       
    }
}