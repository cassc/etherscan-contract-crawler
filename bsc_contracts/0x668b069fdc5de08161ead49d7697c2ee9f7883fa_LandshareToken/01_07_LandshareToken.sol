// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
contract LandshareToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Landshare Token", "LAND") {
        _mint(msg.sender, 3823302533592000000000000);
    }
 
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}