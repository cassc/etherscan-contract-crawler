// SPDX-License-Identifier: MIT
/*
                                 
 _______ _______ _______ _______ 
|\     /|\     /|\     /|\     /|
| +---+ | +---+ | +---+ | +---+ |
| |   | | |   | | |   | | |   | |
| |P  | | |e  | | |p  | | |a  | |
| +---+ | +---+ | +---+ | +---+ |
|/_____\|/_____\|/_____\|/_____\|
                                 



Written By 
__   _______ 
\ \ / /  _  |
 \ V /| | | |
 /   \| | | |
/ /^\ \ \_/ /
\/   \/\___/ 
             
             

                


*/


pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Pepa is ERC20, ERC20Permit, Ownable {
    constructor(address initialOwner)
        ERC20("Pepa", "Pepa")
        ERC20Permit("Pepa")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}