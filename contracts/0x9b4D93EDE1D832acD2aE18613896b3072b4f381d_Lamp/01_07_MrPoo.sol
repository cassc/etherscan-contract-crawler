/*
 /$$        /$$$$$$  /$$      /$$ /$$$$$$$ 
| $$       /$$__  $$| $$$    /$$$| $$__  $$
| $$      | $$  \ $$| $$$$  /$$$$| $$  \ $$
| $$      | $$$$$$$$| $$ $$/$$ $$| $$$$$$$/
| $$      | $$__  $$| $$  $$$| $$| $$____/ 
| $$      | $$  | $$| $$\  $ | $$| $$      
| $$$$$$$$| $$  | $$| $$ \/  | $$| $$      
|________/|__/  |__/|__/     |__/|__/      
                                      
*/
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Lamp is Context, ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("Lamp", "Lamp") {
        _mint(_msgSender(), 69000000 * (10 ** decimals())); 
    }
}