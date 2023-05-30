pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Reduce is Context, ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("Reduce", "RDC") {
        _mint(_msgSender(), 1000000000 * (10 ** decimals())); 
    }
}