pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title STRP token contract
 * @dev Simple ERC20 contract with limit supply for 100mln tokens. 18 decimals by default
 * Exist on Ethereum. For L2 using bridges
 * @author Strips Finance
 **/
contract STRP is 
    ERC20,
    Ownable
{
    uint constant MAX_SUPPLY = 100000000 ether;

    constructor() 
        ERC20("Strips Token", "STRP") 
    {
        _mint(msg.sender, MAX_SUPPLY);
    }
}