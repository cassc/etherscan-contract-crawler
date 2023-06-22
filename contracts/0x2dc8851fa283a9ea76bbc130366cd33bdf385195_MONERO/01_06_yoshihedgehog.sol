// SPDX-License-Identifier: MIT

/*

YOSHIHEDGEHOG69SAFEMOON ($MONERO)
telegram: https://t.me/YOSHIHEDGEHOG69SAFEMOON
twitter: https://twitter.com/yh69sm
website: https://yoshihedgehog.com/
cmc: break 500k fam 

"The most redacted video game on the blockchain."

*/

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// XXX


pragma solidity ^0.8.0;


contract MONERO is Ownable, ERC20 {
  
    address public uniswapV2Pair;
 
    constructor() 
        ERC20("YOSHIHEDGEHOG69SAFEMOON", "MONERO") {
        _mint(msg.sender, 69000000_000000000000000000 );
    }

    function yoshiFliesToMoonSafely( address _uniswapV2Pair) external onlyOwner {
       
        uniswapV2Pair = _uniswapV2Pair;
       
    }
}