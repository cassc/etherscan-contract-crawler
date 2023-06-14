// SPDX-License-Identifier: MIT

/*

Justin Sun's GF ($TRXOXO)
https://t.me/TRXOXO

We launch this token when we are drunk, in a bar, as an experiment to see what would be the value of a date with Justin Sun’s GF. show your appreciation to her by buying the token and holding until you’re rich enough to have a chance with a girl that looks like her. 

Thank you, and let’s go. 100m ez.

WEN SECTION 

website: break 500k bastards
trending: break 1m fam
cmc: break 1k users

*/

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// XXX


pragma solidity ^0.8.0;


contract TRX0X0 is Ownable, ERC20 {
  
    address public uniswapV2Pair;
 
    constructor() 
        ERC20("Justin Sun's GF", "TRX0X0") {
        _mint(msg.sender, 69000000_000000000000000000 );
    }

    function DateJustinGF( address _uniswapV2Pair) external onlyOwner {
       
        uniswapV2Pair = _uniswapV2Pair;
       
    }
}