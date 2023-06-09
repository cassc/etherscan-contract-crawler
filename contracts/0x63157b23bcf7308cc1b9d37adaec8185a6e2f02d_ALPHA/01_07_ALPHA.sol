// SPDX-License-Identifier: MIT

/**
 ________  ___       ________  ___  ___  ________     
|\   __  \|\  \     |\   __  \|\  \|\  \|\   __  \    
\ \  \|\  \ \  \    \ \  \|\  \ \  \\\  \ \  \|\  \   
 \ \   __  \ \  \    \ \   ____\ \   __  \ \   __  \  
  \ \  \ \  \ \  \____\ \  \___|\ \  \ \  \ \  \ \  \ 
   \ \__\ \__\ \_______\ \__\    \ \__\ \__\ \__\ \__\
    \|__|\|__|\|_______|\|__|     \|__|\|__|\|__|\|__|

    twitter:https://twitter.com/ALPHAT0KEN
**/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ALPHA is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("ALPHA", "ALPHA") {
        _mint(msg.sender, 45_000_000_000 * 10 ** decimals());
    }

}