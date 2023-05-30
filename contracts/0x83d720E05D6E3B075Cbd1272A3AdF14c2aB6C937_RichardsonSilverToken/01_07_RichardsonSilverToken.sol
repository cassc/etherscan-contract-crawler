// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RichardsonSilverToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Richardson Silver", "RICHS") {
        _mint(msg.sender, 2184 * 10 ** (decimals() - 1));        
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}