// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
    _     _______  _______  _______  _______  _______  _______  _______  _______ 
 __|_|___(  ____ \(  ___  )(  ____ )(  ____ \(  ____ )(  ___  )(  ____ )(  ____ \
(  _____/| (    \/| (   ) || (    )|| (    \/| (    )|| (   ) || (    )|| (    \/
| (|_|__ | |      | |   | || (____)|| (__    | (____)|| |   | || (____)|| (__    
(_____  )| |      | |   | ||  _____)|  __)   |     __)| |   | ||  _____)|  __)   
/\_|_|) || |      | |   | || (      | (      | (\ (   | |   | || (      | (      
\_______)| (____/\| (___) || )      | (____/\| ) \ \__| (___) || )      | (____/\
   |_|   (_______/(_______)|/       (_______/|/   \__/(_______)|/       (_______/                                                                          
                                             

************************************************
*                                              *
*                  Cope Rope                   *
*           https://copeandrope.xyz            *
*       https://medium.com/@coperopenft        *
*       https://twitter.com/coperopenft        *
*                                              *
*                                              *
************************************************

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CopeToken is ERC20, ERC20Burnable{
    constructor(address stakeAddress, address lpAddress) ERC20("COPEPILLS", "COPEPILLS"){
        _mint(stakeAddress, 108613225672 * (10**uint256(decimals())));
        _mint(lpAddress, 1386774328 * (10**uint256(decimals())));
    }
}