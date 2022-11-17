// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
    constructor()
        ERC20("LOVE", "LOVE")
    {
        _mint(msg.sender, 1_000_000 ether);
    }

     function mint(address to, uint256 amount) public  onlyOwner {
        _mint(to, amount);
    }
}