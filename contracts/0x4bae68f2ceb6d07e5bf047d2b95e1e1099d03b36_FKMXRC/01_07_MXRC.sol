// SPDX-License-Identifier: MIT

/**
 ________ ___  __    _____ ______      ___    ___ ________  ________     
|\  _____\\  \|\  \ |\   _ \  _   \   |\  \  /  /|\   __  \|\   ____\    
\ \  \__/\ \  \/  /|\ \  \\\__\ \  \  \ \  \/  / | \  \|\  \ \  \___|    
 \ \   __\\ \   ___  \ \  \\|__| \  \  \ \    / / \ \   _  _\ \  \       
  \ \  \_| \ \  \\ \  \ \  \    \ \  \  /     \/   \ \  \\  \\ \  \____  
   \ \__\   \ \__\\ \__\ \__\    \ \__\/  /\   \    \ \__\\ _\\ \_______\
    \|__|    \|__| \|__|\|__|     \|__/__/ /\ __\    \|__|\|__|\|_______|
                                      |__|/ \|__|                        
                                                                         
                                                                         
**/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FKMXRC is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("FKMXRC", "FKMXRC") {
        _mint(msg.sender, 81_000_000 * 10 ** decimals());
    }

}