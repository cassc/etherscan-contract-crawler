// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'lib/solmate/src/tokens/ERC20.sol';
import 'lib/openzeppelin-contracts/contracts/access/Ownable.sol';

/*

            (`-')           _  (`-'(`-')                    (`-')  _        _    (`-')     (`-')  _ 
 _       <-.(OO )     .->   \-.(OO ( OO).->      .->        ( OO).-/ <-.   (_)   ( OO).->  ( OO).-/ 
 \-,-----,------,),--.'  ,-._.'    /    '._ (`-')----.     (,------,--. )  ,-(`-'/    '._ (,------. 
  |  .--.|   /`. (`-')'.'  (_...--'|'--...__( OO).-.  '     |  .---|  (`-')| ( OO|'--...__)|  .---' 
 /_) (`-'|  |_.' (OO \    /|  |_.' `--.  .--( _) | |  |    (|  '--.|  |OO )|  |  `--.  .--(|  '--.  
 ||  |OO |  .   .'|  /   /)|  .___.'  |  |   \|  |)|  |     |  .--(|  '__ (|  |_/   |  |   |  .--'  
(_'  '--'|  |\  \ `-/   /` |  |       |  |    '  '-'  '     |  `---|     |'|  |'->  |  |   |  `---. 
   `-----`--' '--'  `--'   `--'       `--'     `-----'      `------`-----' `--'     `--'   `------' 

*/

// twitter: @narky
contract CryptoEliteCoin is ERC20, Ownable {

    constructor(address _narky) ERC20('Crypto Elite Coin', 'ELITE', 18) {
        _mint(_narky, 100000000000 ether);
        _transferOwnership(_narky);
    }

}