// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BraqToken is ERC20, Ownable {
    uint256 public publicSaleSupply = 3750000;

    constructor() ERC20("BRAQToken", "BRAQ") {}
        
    function mint(
    address _to,
    uint256 _amount // Amount in Braq tokens
    ) external onlyOwner { 
        require(_to != address(0), "Error: Insert a valid address"); 
        _mint(_to, _amount * 10 ** decimals());
    }
    
}