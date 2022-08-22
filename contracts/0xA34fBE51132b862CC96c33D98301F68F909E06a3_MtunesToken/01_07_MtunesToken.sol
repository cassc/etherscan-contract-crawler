// MtunesToken Contract
// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MtunesToken is ERC20, Ownable, ERC20Burnable {
    constructor() ERC20("Mtunes Token", "MT") {
        
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }     
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);        
    }
}