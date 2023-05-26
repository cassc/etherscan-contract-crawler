pragma solidity ^0.5.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

/**
 * @title Token is a basic ERC20 Token
 */
contract Token is ERC20, Ownable {
    /**
     * @dev assign totalSupply to account creating this contract */    
    string  public name = "CloutContracts";
    string  public symbol = "CCS"; 
    constructor() public 
    {
        _mint(msg.sender, 111000000);
    }
}