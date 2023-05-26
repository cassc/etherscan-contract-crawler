/* 
//SPDX-License-Identifier: MIT 

TG: https://t.me/shillcoin420
Twitter: https://www.twitter.com/shillcoin420


 _______          _________ _        _       
(  ____ \|\     /|\__   __/( \      ( \      
| (    \/| )   ( |   ) (   | (      | (      
| (_____ | (___) |   | |   | |      | |      
(_____  )|  ___  |   | |   | |      | |      
      ) || (   ) |   | |   | |      | |      
/\____) || )   ( |___) (___| (____/\| (____/\
\_______)|/     \|\_______/(_______/(_______/


//FOR MARKETING FUNDS | ETH TRENDING, DEX TOOLS, CALLERS ETC.
marketingWallet  0xEe01723dD853D43a16a0c95e77a36d06644d76BF

//DEV FOOD , SO i CAN KEEP GOING
teamWallet  0xBF4563b95366c96d83Ac9AAe97241B63C8CF06a9
                                            

*/
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SHILL is Ownable, ERC20 {
    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    address  marketingWallet  = 0xEe01723dD853D43a16a0c95e77a36d06644d76BF;
    address  teamWallet  = 0xBF4563b95366c96d83Ac9AAe97241B63C8CF06a9;


    constructor() ERC20("$SHILL", "SHILL") {
        
        _mint(msg.sender, 500000000000000000000000000);
        _mint(marketingWallet, 100000000000000000000000000);
         _mint(teamWallet, 50000000000000000000000000);
         _mint(0x000000000000000000000000000000000000dEaD,350000000000000000000000000);

 
    }

}