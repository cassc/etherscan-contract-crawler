/*
https://t.me/xiexiecoin                                  
*/
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract XieXie is Context, ERC20, Ownable {
    
    constructor() ERC20( unicode"谢谢",unicode"Xie Xie") {
        _mint(_msgSender(), 1000000000 * (10 ** decimals())); 
    }
}