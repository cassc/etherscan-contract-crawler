// SPDX-License-Identifier: MIT
/*
                                   ,/
                                 ,'/
                               ,' /
                             ,'  /_____,
                           .'____ ♥  ,'    ZAP TO THE EXTREME!
                                /  ,'
                               / ,'
                              /,'
                             /'
*/
pragma solidity ^0.8.9;

import "ERC20.sol";

contract CWCoin is ERC20 {
    // No limits, but chill with those 40% buys, you know what you did.
    uint256 _totalSupply = 19820224000 * 10 ** 18;
    constructor() ERC20("CWCoin", "CWC") {
         _mint(msg.sender, _totalSupply);
         
    }
}
