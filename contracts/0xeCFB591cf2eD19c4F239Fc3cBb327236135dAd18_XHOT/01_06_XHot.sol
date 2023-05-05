// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XHOT is ERC20, Ownable {

    constructor() ERC20("xHot", "XHOT") {
      
      uint256 initialSupply = 1000000000 * 10 ** decimals();
      _mint(msg.sender, initialSupply);
    }

    
    function mint(uint256 _amount) external onlyOwner {
      _mint(msg.sender, _amount);
    }
    
    function burn(uint256 _amount) external onlyOwner {
      _burn(msg.sender, _amount);
    }
    
  }