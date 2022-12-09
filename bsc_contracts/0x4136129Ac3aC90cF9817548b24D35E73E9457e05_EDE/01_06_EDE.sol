// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EDE is ERC20, Ownable {
    constructor() ERC20("EDE", "EDE") {
        uint256 initialSupply = 30300000 * (10 ** 18);
        _mint(msg.sender, initialSupply);
    }
    
    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }
}