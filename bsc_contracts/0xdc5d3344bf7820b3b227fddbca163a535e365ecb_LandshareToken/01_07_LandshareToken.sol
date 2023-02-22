// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
 
contract LandshareToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Landshare Token", "LAND") {
        _mint(msg.sender, 4000000 * 10 ** decimals());
    }
 
    function mint(address to, uint256 amount) public onlyOwner {
         require(totalSupply() + amount <= 10000000000000000000000000, "supply cap reached.");
        _mint(to, amount);
    }
}